import 'package:chat_uikit_demo/pages/call/call_pages/call_button.dart';
import 'package:chat_uikit_demo/pages/call/call_pages/multi_call_item_view.dart';
import 'package:chat_uikit_demo/pages/call/call_pages/multi_call_view.dart';
import 'package:chat_uikit_demo/pages/call/group_member_select_view.dart';
import 'package:em_chat_callkit/chat_callkit.dart';
import 'package:em_chat_uikit/chat_uikit.dart';

import 'package:flutter/material.dart';

class MultiCallPage extends StatefulWidget {
  factory MultiCallPage.call(
    List<String> userList, {
    String? groupId,
    Widget? avatar,
    String? nickname,
    TextStyle? nicknameTextStyle,
  }) {
    return MultiCallPage(
      userList: userList,
      isCaller: true,
      avatar: avatar,
      nickname: nickname,
      groupId: groupId,
      nicknameTextStyle: nicknameTextStyle,
    );
  }

  factory MultiCallPage.receive(
    String callId,
    String caller, {
    String? groupId,
    Widget? avatar,
    String? nickname,
    TextStyle? nicknameTextStyle,
  }) {
    return MultiCallPage(
      isCaller: false,
      callId: callId,
      caller: caller,
      avatar: avatar,
      groupId: groupId,
      nickname: nickname,
      nicknameTextStyle: nicknameTextStyle,
    );
  }

  const MultiCallPage({
    required this.isCaller,
    this.groupId,
    this.userList,
    this.caller,
    this.callId,
    this.avatar,
    this.nickname,
    this.nicknameTextStyle,
    super.key,
  });
  final bool isCaller;
  final String? caller;
  final String? callId;
  final Widget? avatar;
  final String? nickname;
  final List<String>? userList;
  final TextStyle? nicknameTextStyle;
  final String? groupId;

  @override
  State<MultiCallPage> createState() => _MultiCallPageState();
}

class _MultiCallPageState extends State<MultiCallPage> with ChatCallKitObserver, ChatUIKitProviderObserver {
  final PageController _controller = PageController();
  bool mute = false;
  bool cameraOn = true;
  bool isCalling = false;
  List<MultiCallItemView> list = [];
  List<String>? currentList;
  String? callId;
  @override
  void initState() {
    super.initState();
    ChatCallKitManager.addObserver(this);
    ChatUIKitProvider.instance.addObserver(this);
    currentList = widget.userList;
    ChatCallKitManager.initRTC().then((value) {
      afterInit();
    });
  }

  Future<void> afterInit() async {
    if (widget.isCaller && widget.userList != null) {
      isCalling = true;
      Map<String, String>? ext;
      if (widget.groupId != null) {
        ext = {'groupId': widget.groupId!};
      }
      callId = await ChatCallKitManager.startInviteUsers(widget.userList!, ext: ext);
    }

    currentList?.forEach((element) {
      ChatUIKitProfile? profile = ChatUIKitProvider.instance.profilesCache[element];
      profile ??= ChatUIKitProfile.contact(id: element);
      list.add(MultiCallItemView(
        profile: profile,
      ));
    });

    ChatUIKitProfile? current = ChatUIKitProvider.instance.currentUserProfile;
    current ??= ChatUIKitProfile.contact(id: ChatUIKit.instance.currentUserId!);
    list.insert(
        0,
        MultiCallItemView(
          profile: current,
          isWaiting: false,
          videoView: ChatCallKitManager.getLocalVideoView(),
        ));
    setState(() {});
  }

  @override
  void onUserMuteAudio(agoraUid, muted) {
    int index = list.indexWhere((element) => element.agoraUid == agoraUid);
    if (index != -1) {
      MultiCallItemView view = list[index];
      view = view.copyWith(muteAudio: muted);
      list[index] = view;
      setState(() {});
    }
  }

  @override
  void onUserMuteVideo(agoraUid, muted) {
    int index = list.indexWhere((element) => element.agoraUid == agoraUid);
    if (index != -1) {
      MultiCallItemView view = list[index];
      view = view.copyWith(muteVideo: muted);
      list[index] = view;
      setState(() {});
    }
  }

  @override
  void onUserJoined(agoraUid, userId) {
    setState(() {
      list.removeWhere((element) => element.profile?.id == userId || element.agoraUid == agoraUid);
      ChatUIKitProfile? profile = ChatUIKitProvider.instance.profilesCache[userId];
      list.add(MultiCallItemView(
        agoraUid: agoraUid,
        profile: profile,
        isWaiting: false,
        videoView: ChatCallKitManager.getRemoteVideoView(agoraUid),
      ));
    });
  }

  @override
  void onUserLeaved(agoraUid, userId) {
    setState(() {
      list.removeWhere((element) => element.profile?.id == userId || element.agoraUid == agoraUid);
    });
  }

  @override
  void onCallEnd(callId, reason) {
    Navigator.of(context).pop();
  }

  @override
  void onUserRemoved(callId, userId, reason) {
    setState(() {
      list.removeWhere((element) => element.profile?.id == userId);
    });
  }

  @override
  void dispose() {
    ChatUIKitProvider.instance.removeObserver(this);
    ChatCallKitManager.removeObserver(this);
    ChatCallKitManager.releaseRTC();
    super.dispose();
  }

  @override
  void onProfilesUpdate(
    Map<String, ChatUIKitProfile> map,
  ) {
    bool needReload = false;
    for (var i = 0; i < list.length; i++) {
      if (map.containsKey(list[i].profile?.id)) {
        MultiCallItemView view = list[i];
        view = view.copyWith(profile: map[list[i].profile?.id]);
        list[i] = view;
        needReload = true;
      }
    }
    if (needReload) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> children = [];

    for (var i = 0; i < list.length; i += 4) {
      int tmp = i + 4;
      if (tmp > list.length) {
        tmp = list.length;
      }
      children.add(
        MultiCallView(
          list.sublist(i, tmp),
        ),
      );
    }

    Widget content = PageView(
      controller: _controller,
      scrollDirection: Axis.horizontal,
      physics: const ClampingScrollPhysics(),
      children: children,
    );

    List<Widget> bottomList = [];
    if (widget.isCaller || isCalling) {
      bottomList = [cameraButton(), muteButton(), hangupButton()];
    } else {
      bottomList = [cameraButton(), hangupButton(), answerButton()];
    }

    content = Column(
      mainAxisSize: MainAxisSize.max,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Expanded(child: content),
        SizedBox(
          height: 143,
          child: bottomWidget(bottomList),
        ),
      ],
    );

    List<Widget> topWidget = [switchCameraButton(), const SizedBox(width: 10)];
    if (isCalling) {
      topWidget.addAll([inviteUserButton(), const SizedBox(width: 10)]);
    }

    Widget top = SafeArea(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: topWidget,
      ),
    );

    content = Stack(
      children: [
        Positioned(child: content),
        Positioned(top: 0, left: 0, right: 0, child: top),
        () {
          return !isCalling ? beforeCallingWidget() : Container();
        }()
      ],
    );

    content = Scaffold(
      body: content,
    );
    return content;
  }

  // 被叫接听前ui
  Widget beforeCallingWidget() {
    ChatUIKitProfile? profile = ChatUIKitProvider.instance.profilesCache[widget.caller];
    ChatUIKitAvatar avatar = ChatUIKitAvatar(
      avatarUrl: profile?.avatarUrl,
      size: 100,
    );

    Widget content = Column(
      children: [
        avatar,
        const SizedBox(height: 10),
        Text(
          profile?.showName ?? widget.caller ?? "",
          style: widget.nicknameTextStyle ??
              const TextStyle(fontWeight: FontWeight.w600, color: Colors.white, fontSize: 24),
        ),
        const SizedBox(height: 10),
        const Text(
          '邀请您加入多人通话',
          style: TextStyle(
            fontWeight: FontWeight.w400,
            color: Colors.white,
            fontSize: 14,
          ),
        )
      ],
    );

    content = Positioned(left: 0, right: 0, top: 120, child: content);

    return content;
  }

  Widget bottomWidget(List<Widget> widgets) {
    return Stack(
      children: [
        Positioned.fill(
          child: Container(color: Colors.black),
        ),
        Positioned.fill(
            child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          mainAxisSize: MainAxisSize.max,
          children: widgets,
        ))
      ],
    );
  }

  Widget hangupButton() {
    return CallButton(
      selected: false,
      callback: () async {
        await ChatCallKitManager.hangup(widget.callId ?? callId!);
      },
      selectImage: Image.asset("assets/call/hang_up.png"),
      backgroundColor: const Color.fromRGBO(246, 50, 77, 1),
    );
  }

  Widget answerButton() {
    return CallButton(
      selected: false,
      callback: () async {
        await ChatCallKitManager.answer(widget.callId!);
        setState(() => isCalling = true);
      },
      selectImage: Image.asset("assets/call/answer.png"),
      backgroundColor: const Color.fromRGBO(0, 206, 118, 1),
    );
  }

  Widget cameraButton() {
    return CallButton(
      selected: cameraOn,
      callback: () async {
        cameraOn = !cameraOn;
        if (cameraOn) {
          await ChatCallKitManager.cameraOn();
        } else {
          await ChatCallKitManager.cameraOff();
        }
        String? currentUserId = ChatCallKitClient.getInstance.currentUserId;
        int index = list.indexWhere((element) => currentUserId != null && element.profile?.id == currentUserId);
        if (index != -1) {
          MultiCallItemView view = list[index];
          view = view.copyWith(muteVideo: !cameraOn);
          list[index] = view;
        }
        setState(() {});
      },
      selectImage: Image.asset("assets/call/video_on.png"),
      unselectImage: Image.asset("assets/call/video_off.png"),
      backgroundColor: cameraOn ? const Color.fromRGBO(255, 255, 255, 0.2) : Colors.white,
    );
  }

  Widget muteButton() {
    return CallButton(
      selected: mute,
      callback: () async {
        mute = !mute;
        if (mute) {
          await ChatCallKitManager.mute();
        } else {
          await ChatCallKitManager.unMute();
        }
        setState(() {});
      },
      selectImage: Image.asset("assets/call/mic_off.png"),
      unselectImage: Image.asset("assets/call/mic_on.png"),
    );
  }

  Widget switchCameraButton() {
    return button('switch_camera', () {
      ChatCallKitManager.switchCamera();
    });
  }

  Widget inviteUserButton() {
    return button('invite_user', () {
      if (widget.groupId == null) {
        return;
      }
      Navigator.of(context)
          .push(
        MaterialPageRoute(
          builder: (context) => GroupMemberSelectView(groupId: widget.groupId!),
        ),
      )
          .then((value) {
        if (value is List<ChatUIKitProfile> && value.isNotEmpty) {
          List<String> userIds = value.map((e) => e.id).toList();
          ChatCallKitManager.startInviteUsers(userIds, ext: {'groupId': widget.groupId!}).then((value) {
            for (var element in userIds) {
              ChatUIKitProfile? profile = ChatUIKitProvider.instance.profilesCache[element];
              profile ??= ChatUIKitProfile.contact(id: element);
              list.add(MultiCallItemView(profile: profile));
            }
            setState(() {});
          });
        }
      });
    });
  }

  Widget button(String imageName, VoidCallback action) {
    return InkWell(
      onTap: action,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: const Color.fromRGBO(255, 255, 255, 0.2),
        ),
        child: Image.asset('assets/call/$imageName.png'),
      ),
    );
  }
}
