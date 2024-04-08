import 'dart:ui';

import 'package:em_chat_uikit/chat_uikit.dart';
import 'package:flutter/material.dart';

class MultiCallItemView extends StatelessWidget {
  const MultiCallItemView({
    this.agoraUid,
    this.profile,
    this.videoView,
    this.muteAudio = false,
    this.muteVideo = false,
    this.isWaiting = true,
    super.key,
  });
  final int? agoraUid;
  final bool muteVideo;
  final bool muteAudio;
  final Widget? videoView;
  final bool isWaiting;
  final ChatUIKitProfile? profile;

  MultiCallItemView copyWith({bool? muteAudio, bool? muteVideo, bool? isWaiting, ChatUIKitProfile? profile}) {
    return MultiCallItemView(
      agoraUid: agoraUid,
      profile: profile ?? this.profile,
      videoView: videoView,
      muteAudio: muteAudio ?? this.muteAudio,
      muteVideo: muteVideo ?? this.muteVideo,
      isWaiting: isWaiting ?? this.isWaiting,
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget content = ChatUIKitAvatar(avatarUrl: profile?.avatarUrl);

    Widget background = Container(
      color: Colors.black87,
      child: ChatUIKitAvatar(avatarUrl: profile?.avatarUrl),
    );

    List<Widget> list = [
      const SizedBox(width: 10),
      Text(
        profile?.showName ?? agoraUid.toString(),
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white),
      ),
      const Expanded(child: Offstage())
    ];

    if (muteVideo == true) {
      list.add(SizedBox(
        width: 18,
        height: 24,
        child: Image.asset('images/video_off.png', color: Colors.white),
      ));
    }
    list.add(const SizedBox(width: 5));
    if (muteAudio == true) {
      list.add(SizedBox(
        width: 18,
        height: 24,
        child: Image.asset('images/mic_off.png', color: Colors.white),
      ));
    }
    list.add(const SizedBox(width: 10));

    Widget bottom = Row(
      mainAxisSize: MainAxisSize.max,
      children: list,
    );

    List<Widget> positionList = [
      Positioned.fill(child: background),
      Positioned.fill(
        child: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(color: const Color.fromRGBO(0, 0, 0, 0.4)),
          ),
        ),
      ),
      Positioned(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              flex: 1,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    clipBehavior: Clip.hardEdge,
                    decoration: const BoxDecoration(
                      borderRadius: BorderRadius.all(Radius.circular(50)),
                    ),
                    width: 100,
                    height: 100,
                    child: content,
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 1,
              child: Container(),
            )
          ],
        ),
      ),
      Positioned(child: muteVideo ? Container() : videoView ?? Container()),
      Positioned(
        left: 0,
        right: 0,
        bottom: 0,
        child: SizedBox(
          height: 33,
          child: bottom,
        ),
      ),
    ];

    if (isWaiting) {
      positionList.add(const Center(
        child: CircularProgressIndicator(
          strokeWidth: 5.0,
          color: Colors.grey,
        ),
      ));
    }

    content = Stack(children: positionList);

    return content;
  }
}
