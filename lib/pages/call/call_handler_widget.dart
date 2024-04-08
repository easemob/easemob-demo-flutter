import 'package:chat_uikit_demo/demo_config.dart';
import 'package:chat_uikit_demo/pages/call/call_pages/multi_call_page.dart';
import 'package:chat_uikit_demo/pages/call/call_pages/single_call_page.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:chat_uikit_demo/tool/app_server_helper.dart';
import 'package:em_chat_callkit/chat_callkit.dart';
import 'package:em_chat_uikit/chat_uikit.dart';
import 'package:flutter/material.dart';

class CallHandlerWidget extends StatefulWidget {
  const CallHandlerWidget({required this.child, super.key});

  final Widget child;

  @override
  State<CallHandlerWidget> createState() => _CallHandlerWidgetState();
}

class _CallHandlerWidgetState extends State<CallHandlerWidget> with ChatCallKitObserver {
  @override
  void initState() {
    super.initState();
    ChatCallKitManager.addObserver(this);
    // 获取rtc token
    ChatCallKitManager.setRTCTokenHandler((channel, agoraAppId) async {
      String? userId = ChatUIKit.instance.currentUserId;
      Map<String, int> ret = {};
      if (userId != null) {
        try {
          AgoraInfo info = await AppServerHelper.fetchAgoraInfo(userId, channelName: channel);
          ret[info.agoraToken] = int.parse(info.agoraUid);
        } catch (e) {
          debugPrint('Failed to fetch agora info: $e');
        }
      }
      return ret;
    });

    // set agoraUid and userId mapper handler.
    ChatCallKitManager.setUserMapperHandler((channel, agoraUid) async {
      Map<String, String> map = await AppServerHelper.fetchAgoraUidMap(channel);
      Map<int, String> ret = {};
      for (var element in map.keys) {
        ret[int.parse(element)] = map[element]!;
      }
      ChatCallKitUserMapper userMap = ChatCallKitUserMapper(channel, ret);
      return userMap;
    });
  }

  @override
  void dispose() {
    ChatCallKitManager.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 添加call kit相关监听初始化
    return ChatCallKit(agoraAppId: rtcAppId, child: widget.child);
  }

  @override
  void onReceiveCall(
    String userId,
    String callId,
    ChatCallKitCallType callType,
    Map<String, String>? ext,
  ) async {
    debugPrint('----onReceiveCall: $userId, $callId, $callType, $ext');
    pushToCallPage(
      [userId],
      callType,
      callId: callId,
      ext: ext,
    );
  }

  void pushToCallPage(
    List<String> userIds,
    ChatCallKitCallType callType, {
    String? callId,
    Map<String, String>? ext,
  }) async {
    Widget page;
    String? groupId = ext?['groupId'];
    if (callType == ChatCallKitCallType.multi) {
      if (callId == null) {
        page = MultiCallPage.call(userIds, groupId: groupId);
      } else {
        page = MultiCallPage.receive(callId, userIds.first, groupId: groupId);
      }
    } else {
      if (callId == null) {
        page = SingleCallPage.call(userIds.first, type: callType);
      } else {
        page = SingleCallPage.receive(userIds.first, callId, type: callType);
      }
    }

    [Permission.microphone, Permission.camera].request().then((value) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (context) {
          return page;
        }),
      ).then((value) {
        if (value != null) {
          debugPrint('call end: $value');
        }
      });
    });
  }
}
