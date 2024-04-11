import 'package:chat_uikit_demo/tool/app_server_helper.dart';
import 'package:chat_uikit_demo/tool/user_data_store.dart';
import 'package:em_chat_uikit/chat_uikit.dart';

import 'package:flutter/material.dart';
import 'package:lpinyin/lpinyin.dart';

class UserProviderHandlerWidget extends StatefulWidget {
  const UserProviderHandlerWidget({required this.child, super.key});

  final Widget child;

  @override
  State<UserProviderHandlerWidget> createState() => _UserProviderHandlerWidgetState();
}

class _UserProviderHandlerWidgetState extends State<UserProviderHandlerWidget>
    with GroupObserver, ChatUIKitProviderObserver {
  @override
  void initState() {
    super.initState();
    ChatUIKit.instance.addObserver(this);
    // 打开db
    UserDataStore().init(onOpened: onOpened);
    // 设置Provider回调
    ChatUIKitProvider.instance.profilesHandler = onProfilesRequest;
    ChatUIKitAlphabetSortHelper.instance.sortHandler = onAlphabetSortLetterRequest;
  }

  @override
  void dispose() {
    ChatUIKit.instance.removeObserver(this);
    // 清空所有uikit缓存
    ChatUIKitProvider.instance.clearAllCache();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }

  void onOpened() async {
    // 1. 将所有存储的数据填充到uikit中。
    await addAllUserInfoToProvider();
    // 2. 加载群组信息, 并判断是否已经填充到uikit中。如果没有，从服务器获取数据，之后填充到uikit中。
    await loadGroupInfos();
    // 2. 加载用户信息, 并判断是否已经填充到uikit中。如果没有，从服务器获取数据，之后填充到uikit中。
    await loadUserInfos();
    // 3. 获取当前用户信息，之后填充到uikit中。
    await fetchCurrentUserInfo();
  }

  Future<void> fetchCurrentUserInfo() async {
    try {
      // 自己的数据不从db中取，每次都从服务区获取最新数据。
      Map<String, UserInfo> map = await ChatUIKit.instance.fetchUserInfoByIds([ChatUIKit.instance.currentUserId!]);
      ChatUIKitProfile profile = ChatUIKitProfile.contact(
        id: map.values.first.userId,
        nickname: map.values.first.nickName,
        avatarUrl: map.values.first.avatarUrl,
      );
      UserDataStore().saveUserData(profile);
      ChatUIKitProvider.instance.addProfiles([profile]);
    } catch (e) {
      debugPrint('fetchCurrentUserInfo error: $e');
    }
  }

  // 返回排序用首字母，比如中文显示时，可以返回首字母以便排序
  String onAlphabetSortLetterRequest(String showName) {
    return PinyinHelper.getPinyinE(showName, defPinyin: '#', format: PinyinFormat.WITHOUT_TONE).substring(0, 1);
  }

  // uikit 需要展示用户信息时，而缓存不存在时会回调该方法，如果demo缓存中有数据，可以直接返回，如果没有则异步从服务器获取数据，同时把返回null。
  List<ChatUIKitProfile>? onProfilesRequest(List<ChatUIKitProfile> profiles) {
    // 判断是否是用户信息，如果是用户信息，调用fetchUserInfos，具体实现查看 [fetchUserInfos]。
    List<String> userIds = profiles.where((e) => e.type == ChatUIKitProfileType.contact).map((e) => e.id).toList();
    if (userIds.isNotEmpty) {
      fetchUserInfos(userIds);
    }

    // 判断是否是群组信息，如果是群组信息，调用updateGroupsProfile，具体实现查看 [updateGroupsProfile]。
    List<String> groupIds = profiles.where((e) => e.type == ChatUIKitProfileType.group).map((e) => e.id).toList();
    if (groupIds.isNotEmpty) {
      updateGroupsProfile(groupIds);
    }

    return null;
  }

  @override
  void onGroupCreatedByMyself(Group group) async {
    ChatUIKitProfile? profile;
    try {
      String? avatar = await AppServerHelper.fetchGroupAvatar(group.groupId);
      profile = ChatUIKitProfile.group(id: group.groupId, groupName: group.name, avatarUrl: avatar);
    } catch (e) {
      debugPrint('fetchGroupAvatar error: $e');
    } finally {
      profile ??= ChatUIKitProfile.group(id: group.groupId, groupName: group.name);
      ChatUIKitProvider.instance.addProfiles([profile]);
      UserDataStore().saveUserData(profile);
    }
  }

  @override
  void onGroupNameChangedByMeSelf(Group group) {
    ChatUIKitProfile? profile = ChatUIKitProvider.instance.profilesCache[group.groupId];
    if (profile != null) {
      ChatUIKitProvider.instance.addProfiles(
        [ChatUIKitProfile.group(id: group.groupId, groupName: group.name, avatarUrl: profile.avatarUrl)],
      );
    } else {
      ChatUIKitProvider.instance.addProfiles(
        [ChatUIKitProfile.group(id: group.groupId, groupName: group.name)],
      );
    }
  }

  @override
  void onSpecificationDidUpdate(Group group) async {
    ChatUIKitProfile profile = ChatUIKitProfile.group(
      id: group.groupId,
      groupName: group.name,
      avatarUrl: group.extension,
    );
    ChatUIKitProvider.instance.addProfiles([profile]);
  }

  Future<void> addAllUserInfoToProvider() async {
    // 1. 从本地获取所有用户属性填充到uikit中。
    List<ChatUIKitProfile> list = await UserDataStore().loadAllProfiles();
    ChatUIKitProvider.instance.addProfiles(list);
  }

  // 获取所有已加入的群组，并将缓存数据返回给 uikit 缓存。
  Future<void> loadGroupInfos() async {
    List<Group> groups = await ChatUIKit.instance.getJoinedGroups();
    List<ChatUIKitProfile> profiles = [];
    for (var group in groups) {
      ChatUIKitProfile? profile = ChatUIKitProvider.instance.profilesCache[group.groupId];
      if (profile != null) {
        profile = profile.copyWith(name: group.name);
      } else {
        profile = ChatUIKitProfile.group(id: group.groupId, groupName: group.name, avatarUrl: group.extension);
      }
      profiles.add(profile);
    }
    if (profiles.isNotEmpty) {
      UserDataStore().saveUserDatas(profiles);
      ChatUIKitProvider.instance.addProfiles(profiles);
    }
  }

  Future<void> updateGroupsProfile(List<String> groupIds) async {
    List<ChatUIKitProfile> list = [];
    try {
      for (var groupId in groupIds) {
        Group group = await ChatUIKit.instance.fetchGroupInfo(groupId: groupId);
        ChatUIKitProfile profile =
            ChatUIKitProfile.group(id: group.groupId, groupName: group.name, avatarUrl: group.extension);
        list.add(profile);
      }
      UserDataStore().saveUserDatas(list);
      ChatUIKitProvider.instance.addProfiles(list);
    } catch (e) {
      debugPrint('loadGroupInfo error: $e');
    }
  }

  Future<void> loadUserInfos() async {
    try {
      // 1. 从本地获取所有用户属性填充到uikit中。
      Map<String, ChatUIKitProfile> map = ChatUIKitProvider.instance.profilesCache;
      // 2. 从 sdk中获取所有好友，如果有新的好友从服务器获取新的好友属性保存到本地并填充到uikit中。
      List<Contact> contacts = await ChatUIKit.instance.getAllContacts();
      contacts.removeWhere((element) => map.keys.contains(element.userId));
      if (contacts.isNotEmpty) {
        List<String> userIds = contacts.map((e) => e.userId).toList();
        fetchUserInfos(userIds);
      }
    } catch (e) {
      debugPrint('loadUserInfos error: $e');
    }
  }

  void fetchUserInfos(List<String> userIds) async {
    try {
      Map<String, UserInfo> map = await ChatUIKit.instance.fetchUserInfoByIds(userIds);
      List<Contact> contacts = await ChatUIKit.instance.getAllContacts();
      List<ChatUIKitProfile> list = [];
      for (var element in map.values) {
        int index = contacts.indexWhere((e) => e.userId == element.userId);
        list.add(ChatUIKitProfile.contact(
          id: element.userId,
          nickname: element.nickName,
          avatarUrl: element.avatarUrl,
          remark: index != -1 ? contacts[index].remark : null,
        ));
      }

      UserDataStore().saveUserDatas(list);
      ChatUIKitProvider.instance.addProfiles(list);
    } catch (e) {
      debugPrint('fetchUserInfos error: $e');
    }
  }
}
