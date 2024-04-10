import 'dart:async';

import 'package:chat_uikit_demo/demo_localizations.dart';
import 'package:chat_uikit_demo/pages/call/call_pages/call_button.dart';
import 'package:chat_uikit_demo/tool/format_time_tool.dart';
import 'package:em_chat_callkit/chat_callkit.dart';
import 'package:em_chat_uikit/chat_uikit.dart';

import 'package:flutter/material.dart';
import 'package:flutter_ringtone_player/flutter_ringtone_player.dart';

enum SingleCallType {
  // 音频呼入等待
  audioCallInHolding,
  // 视频呼入等待
  videoCallInHolding,
  // 音频呼出等待
  audioCallOutHolding,
  // 视频呼出等待
  videoCallOutHolding,
  // 音频通话中
  audioCallCalling,
  // 视频通话中
  videoCallCalling,
}

class SingleCallPage extends StatefulWidget {
  factory SingleCallPage.receive(
    String userId,
    String callId, {
    ChatCallKitCallType type = ChatCallKitCallType.audio_1v1,
    Widget? backgroundWidget,
    TextStyle? nicknameTextStyle,
  }) {
    assert(type != ChatCallKitCallType.multi, "SingleCallPage must video_1v1 or audio_1v1 type.");

    return SingleCallPage(
      userId,
      callId: callId,
      type: type,
      backgroundWidget: backgroundWidget,
      nicknameTextStyle: nicknameTextStyle,
    );
  }

  factory SingleCallPage.call(
    String userId, {
    ChatCallKitCallType type = ChatCallKitCallType.audio_1v1,
    Widget? backgroundWidget,
    TextStyle? nicknameTextStyle,
  }) {
    assert(type != ChatCallKitCallType.multi, "SingleCallPage must video_1v1 or audio_1v1 type.");

    return SingleCallPage(
      userId,
      type: type,
      backgroundWidget: backgroundWidget,
      nicknameTextStyle: nicknameTextStyle,
    );
  }

  const SingleCallPage(
    this.userId, {
    this.callId,
    this.backgroundWidget,
    this.nicknameTextStyle,
    this.timeTextStyle,
    this.type = ChatCallKitCallType.audio_1v1,
    this.calling = false,
    super.key,
  });
  final String userId;
  final Widget? backgroundWidget;
  final TextStyle? nicknameTextStyle;
  final TextStyle? timeTextStyle;
  final ChatCallKitCallType type;
  final String? callId;
  final bool calling;

  @override
  State<SingleCallPage> createState() => _SingleCallPageState();
}

class _SingleCallPageState extends State<SingleCallPage> with ChatCallKitObserver, ChatUIKitProviderObserver {
  bool holding = true;
  bool speakerOn = false;
  bool mute = false;
  bool cameraOn = true;

  bool remoteMute = false;
  int time = 0;
  Timer? timer;
  String? callId;

  bool hangup = false;

  Widget? remoteVideoWidget;

  bool hasInit = false;
  bool backgroundVideo = true;

  late SingleCallType currentType;

  ChatUIKitProfile? profile;

  @override
  void initState() {
    super.initState();
    profile = ChatUIKitProvider.instance.profilesCache[widget.userId];
    profile ??= ChatUIKitProvider.instance.getProfile(ChatUIKitProfile.contact(id: widget.userId));
    ChatUIKitProvider.instance.addObserver(this);
    addListener();

    if (widget.callId != null) {
      if (widget.calling) {
        if (widget.type == ChatCallKitCallType.audio_1v1) {
          currentType = SingleCallType.audioCallCalling;
        } else {
          currentType = SingleCallType.videoCallCalling;
        }
      } else {
        if (widget.type == ChatCallKitCallType.audio_1v1) {
          currentType = SingleCallType.audioCallInHolding;
        } else {
          currentType = SingleCallType.videoCallInHolding;
        }
      }
    } else {
      if (widget.type == ChatCallKitCallType.audio_1v1) {
        currentType = SingleCallType.audioCallOutHolding;
      } else {
        currentType = SingleCallType.videoCallOutHolding;
      }
    }
    ChatCallKitManager.initRTC().then((value) {
      setState(() {
        hasInit = true;
      });
      afterRTCInitAction();
    });
  }

  void afterRTCInitAction() {
    switch (currentType) {
      case SingleCallType.audioCallOutHolding:
      case SingleCallType.videoCallOutHolding:
        call();
        break;
      case SingleCallType.audioCallInHolding:
      case SingleCallType.videoCallInHolding:
        break;
      case SingleCallType.audioCallCalling:
      case SingleCallType.videoCallCalling:
        answer();
        break;
    }
  }

  void answer() async {
    await ChatCallKitManager.answer(widget.callId!);
    holding = false;
    setState(() {});
  }

  void call() async {
    Future(() async {
      try {
        callId = await ChatCallKitManager.startSingleCall(
          widget.userId,
          type: widget.type,
          inviteMessage: widget.type == ChatCallKitCallType.audio_1v1
              ? DemoLocalizations.singleVoiceCallInviteMessage.localString(context)
              : DemoLocalizations.singleVideoCallInviteMessage.localString(context),
        );
      } on ChatCallKitError {
        rethrow;
      }
    }).catchError((e) {
      Navigator.of(context).pop();
    });
  }

  void addListener() {
    ChatCallKitManager.addObserver(this);
  }

  void removeListener() {
    ChatCallKitManager.removeObserver(this);
  }

  @override
  void onUserMuteAudio(int agoraUid, bool muted) {
    setState(() {
      remoteMute = muted;
    });
  }

  @override
  void onProfilesUpdate(
    Map<String, ChatUIKitProfile> map,
  ) {
    if (map.containsKey(profile!.id)) {
      profile = map[profile!.id];
      setState(() {});
    }
  }

  @override
  void onUserMuteVideo(int agoraUid, bool muted) {
    if (widget.type == ChatCallKitCallType.audio_1v1) return;
    if (muted) {
      remoteVideoWidget = Container(color: Colors.black);
    } else {
      remoteVideoWidget = ChatCallKitManager.getRemoteVideoView(agoraUid);
    }

    setState(() {});
  }

  @override
  void onUserJoined(agoraUid, userId) {
    if (userId == widget.userId) {
      startTimer();
    }
  }

  @override
  void onCallEnd(String? callId, ChatCallKitCallEndReason reason) {
    Navigator.of(context).pop();
  }

  void startTimer() {
    holding = false;
    timer?.cancel();
    timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          time++;
        });
      }
    });
  }

  void stopTimer() {
    timer?.cancel();
    timer = null;
  }

  @override
  void dispose() {
    stopTimer();
    removeListener();
    ChatUIKitProvider.instance.removeObserver(this);
    ChatCallKitManager.releaseRTC();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget? content;
    switch (currentType) {
      case SingleCallType.audioCallInHolding:
        {
          content = audioCallInWidget();
        }
        break;
      case SingleCallType.audioCallOutHolding:
      case SingleCallType.audioCallCalling:
        {
          content = audioCallOutWidget();
        }
        break;
      case SingleCallType.videoCallOutHolding:
      case SingleCallType.videoCallInHolding:
      case SingleCallType.videoCallCalling:
        {
          content = videoCallWidget();
        }
        break;
    }

    List<Widget> list = [
      Positioned.fill(child: backgroundWidget()),
      Positioned.fill(child: backgroundMaskWidget()),
      Positioned.fill(
        top: 55,
        bottom: 60,
        child: content,
      ),
    ];

    content = Stack(
      children: list,
    );

    content = Scaffold(
      body: content,
    );
    return content;
  }

  Widget backgroundWidget() {
    return widget.backgroundWidget ?? Container(color: Colors.grey);
  }

  Widget backgroundMaskWidget() {
    if (!hasInit) return const Offstage();
    Widget content;
    if (backgroundVideo && remoteVideoWidget != null) {
      content = remoteWidget();
    } else {
      content = localWidget();
    }

    content = InkWell(
      child: content,
    );

    return content;
  }

  Widget floatWidget() {
    if (!hasInit) return const Offstage();
    Widget content;
    if (!backgroundVideo) {
      content = remoteWidget();
    } else {
      content = localWidget();
    }

    content = SizedBox(
      width: 90,
      height: 160,
      child: content,
    );

    content = InkWell(
      onTap: () {
        setState(() => backgroundVideo = !backgroundVideo);
      },
      child: content,
    );

    return content;
  }

  Widget remoteWidget() {
    return remoteVideoWidget ?? Container();
  }

  Widget localWidget() {
    return cameraOn
        ? ChatCallKitManager.getLocalVideoView() ?? Container(color: Colors.black)
        : Container(color: Colors.black);
  }

  Widget audioCallInWidget() {
    Widget content = avatarWidget();
    content = Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(width: 17.5),
        content,
        const SizedBox(height: 10),
        nicknameWidget(),
        const SizedBox(height: 10),
        timeWidget('Audio Call'),
      ],
    );

    Widget bottom = bottomWidget([
      answerButton(),
      hangupButton(),
    ]);

    content = Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [content, bottom],
    );

    return content;
  }

  Widget audioCallOutWidget() {
    Widget content = avatarWidget();
    content = Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(width: 17.5),
        content,
        const SizedBox(height: 10),
        nicknameWidget(),
        const SizedBox(height: 10),
        timeWidget(),
      ],
    );

    Widget bottom = bottomWidget([
      speakerButton(),
      muteButton(),
      hangupButton(),
    ]);

    content = Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [content, bottom],
    );

    return content;
  }

  Widget videoCallWidget() {
    Widget content = switchCameraButton();
    if (remoteVideoWidget == null) {
      content = Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.end, children: [content, const SizedBox(width: 17.5)]),
          avatarWidget(),
          const SizedBox(height: 10),
          nicknameWidget(),
          const SizedBox(height: 10),
          timeWidget(),
        ],
      );
    } else {
      content = Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.end, children: [content, const SizedBox(width: 17.5)]),
          const SizedBox(height: 10),
          Row(mainAxisAlignment: MainAxisAlignment.end, children: [floatWidget(), const SizedBox(width: 17.5)]),
        ],
      );
    }

    content = Column(
      children: [content, const SizedBox(height: 30)],
    );

    Widget bottom;
    if (currentType == SingleCallType.videoCallCalling || currentType == SingleCallType.videoCallOutHolding) {
      bottom = bottomWidget([cameraButton(), muteButton(), hangupButton()]);
    } else {
      bottom = bottomWidget([cameraButton(), hangupButton(), answerButton()]);
    }

    content = Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [content, bottom],
    );

    return content;
  }

  Widget avatarWidget() {
    return SizedBox(
      width: 100,
      height: 100,
      child: Stack(
        children: [
          ChatUIKitAvatar(
            avatarUrl: profile?.avatarUrl,
            size: 100,
          ),
          remoteMute
              ? Positioned(
                  right: 0,
                  bottom: 0,
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: Image.asset('assets/call/mic_off.png', color: Colors.white),
                  ),
                )
              : const Offstage(),
        ],
      ),
    );
  }

  Widget nicknameWidget() {
    return Text(
      profile?.showName ?? widget.userId,
      style: widget.nicknameTextStyle ??
          const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
    );
  }

  Widget topWidget(List<Widget> list) {
    Widget content = Column(
      children: list,
    );

    content = Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [content, const SizedBox(width: 17.5)],
    );
    return content;
  }

  Widget bottomWidget(List<Widget> widgets) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      mainAxisSize: MainAxisSize.max,
      children: widgets,
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
        setState(() {});
      },
      selectImage: Image.asset("assets/call/video_on.png"),
      unselectImage: Image.asset("assets/call/video_off.png"),
      backgroundColor: cameraOn ? const Color.fromRGBO(255, 255, 255, 0.2) : Colors.white,
    );
  }

  Widget switchCameraButton() {
    return InkWell(
      onTap: () {
        ChatCallKitManager.switchCamera();
      },
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: const Color.fromRGBO(255, 255, 255, 0.2),
        ),
        child: Image.asset('assets/call/switch_camera.png'),
      ),
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
        await FlutterRingtonePlayer().stop();
        await ChatCallKitManager.answer(widget.callId!);
        holding = false;
        setState(() {
          if (widget.type == ChatCallKitCallType.audio_1v1) {
            currentType = SingleCallType.audioCallCalling;
          } else {
            currentType = SingleCallType.videoCallCalling;
          }
        });
      },
      selectImage: Image.asset("assets/call/answer.png"),
      backgroundColor: const Color.fromRGBO(0, 206, 118, 1),
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

  Widget speakerButton() {
    return CallButton(
      selected: speakerOn,
      callback: () async {
        speakerOn = !speakerOn;
        if (speakerOn) {
          await ChatCallKitManager.speakerOn();
        } else {
          await ChatCallKitManager.speakerOff();
        }
        setState(() {});
      },
      selectImage: Image.asset("assets/call/speaker_on.png"),
      unselectImage: Image.asset("assets/call/speaker_off.png"),
    );
  }

  Text timeWidget([String? str]) {
    return Text(
      str ?? (holding ? 'Calling...' : timerToStr(time)),
      textAlign: TextAlign.center,
      style: widget.timeTextStyle ??
          const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w400,
            color: Colors.white,
          ),
    );
  }
}
