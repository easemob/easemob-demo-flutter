import 'package:chat_uikit_demo/demo_localizations.dart';
import 'package:em_chat_uikit/chat_uikit.dart';
import 'package:flutter/material.dart';

class GroupMemberSelectView extends StatefulWidget {
  const GroupMemberSelectView({required this.groupId, super.key});

  final String groupId;

  @override
  State<GroupMemberSelectView> createState() => _GroupMemberSelectViewState();
}

class _GroupMemberSelectViewState extends State<GroupMemberSelectView>
    with ChatUIKitThemeMixin {
  List<ChatUIKitProfile> selected = [];
  late ChatUIKitProfile currentProfile;

  @override
  void initState() {
    super.initState();
    ChatUIKitProfile? profile = ChatUIKitProvider.instance
        .getProfileById(ChatUIKit.instance.currentUserId!);
    profile ??= ChatUIKitProfile.contact(id: ChatUIKit.instance.currentUserId!);
    currentProfile = profile;
    selected.add(profile);
  }

  @override
  Widget themeBuilder(BuildContext context, ChatUIKitTheme theme) {
    return Scaffold(
      appBar: ChatUIKitAppBar(
        title: DemoLocalizations.selectCallee.localString(context),
        centerTitle: false,
        trailingActions: [
          ChatUIKitAppBarAction(
            onTap: (context) {
              if (selected.length <= 1) {
                return;
              }
              selected
                  .removeWhere((element) => element.id == currentProfile.id);
              Navigator.of(context).pop(selected);
            },
            child: Text(
              '${DemoLocalizations.call.localString(context)}(${selected.length})',
              style: ChatUIKitTheme.instance.titleMedium(
                color: selected.length > 1
                    ? (theme.color.isDark
                        ? theme.color.primaryColor6
                        : theme.color.primaryColor5)
                    : (theme.color.isDark
                        ? theme.color.neutralColor4
                        : theme.color.neutralColor7),
              ),
            ),
          )
        ],
      ),
      body: GroupMemberListView(
        onSearchTap: onSearchTap,
        groupId: widget.groupId,
        itemBuilder: (context, model) {
          return InkWell(
            onTap: () {
              if (currentProfile.id == model.profile.id) {
                return;
              }
              setState(() {
                if (selected.any((element) => element.id == model.profile.id)) {
                  selected
                      .removeWhere((element) => element.id == model.profile.id);
                } else {
                  selected.add(model.profile);
                }
              });
            },
            child: Row(
              children: [
                const SizedBox(width: 16),
                selected.any((element) => element.id == model.profile.id)
                    ? Icon(
                        Icons.check_box,
                        size: 24,
                        color: theme.color.primaryColor5,
                      )
                    : Icon(
                        Icons.check_box_outline_blank,
                        size: 24,
                        color: theme.color.primaryColor5,
                      ),
                ChatUIKitContactListViewItem(model),
              ],
            ),
          );
        },
      ),
    );
  }

  void onSearchTap(List<ContactItemModel> data) async {
    List<NeedSearch> list = [];
    for (var item in data) {
      list.add(item);
    }
    ChatUIKitRoute.pushOrPushNamed(
      context,
      ChatUIKitRouteNames.searchView,
      SearchViewArguments(
          canChangeSelected: selected,
          searchHideText: DemoLocalizations.calleeSearch.localString(context),
          searchData: list,
          enableMulti: true,
          cantChangeSelected: [currentProfile]),
    ).then(
      (value) {
        if (value is List<ChatUIKitProfile>) {
          selected = [...value];
          setState(() {});
        }
      },
    );
  }

  void tapContactInfo(ChatUIKitProfile profile) {
    List<ChatUIKitProfile> list = selected;
    if (list.contains(profile)) {
      list.remove(profile);
    } else {
      list.add(profile);
    }
    selected = [...list];
    setState(() {});
  }
}
