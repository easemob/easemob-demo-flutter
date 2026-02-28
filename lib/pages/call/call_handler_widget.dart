import 'package:chat_uikit_demo/demo_config.dart';
import 'package:chat_uikit_demo/pages/call/call_pages/multi_call_page.dart';
import 'package:chat_uikit_demo/pages/call/call_pages/single_call_page.dart';
import 'package:flutter_ringtone_player/flutter_ringtone_player.dart';
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

class _CallHandlerWidgetState extends State<CallHandlerWidget>
    with ChatCallKitObserver {
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
          AgoraInfo info = await AppServerHelper.fetchAgoraInfo(userId,
              channelName: channel);
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
    // 添加call kit相关初始化
    if (DemoConfig.isValid) {
      return ChatCallKit(agoraAppId: DemoConfig.rtcAppId!, child: widget.child);
    } else {
      return const Center(
        child: Text('CallKit is not configured. Please set DemoConfig.'),
      );
    }
  }

  // 呼叫结束
  @override
  void onCallEnd(ChatCallKitCall? call, ChatCallKitCallEndReason reason) {
    FlutterRingtonePlayer().stop();
    // 通知消息列表刷新，以显示通话记录消息
    _updateMessage(call?.inviteMessageId);
  }

  // 收到呼叫邀请
  @override
  void onReceiveCall(
    String userId,
    String callId,
    ChatCallKitCallType callType,
    Map<String, String>? ext,
  ) async {
    FlutterRingtonePlayer().play(
      android: AndroidSounds.ringtone,
      ios: IosSounds.electronic,
      looping: true,
      volume: 0.1,
      asAlarm: false,
    );

    pushToCallPage(
      [userId],
      callType,
      callId,
      ext: ext,
    );
  }

  // 邀请信息将要发送
  @override
  void onInviteMessageWillSend(ChatCallKitMessage message) {
    // ignore: invalid_use_of_protected_member
    ChatUIKit.instance.onMessagesReceived([message]);
  }

  void _updateMessage(String? inviteMessageId) async {
    if (inviteMessageId != null) {
      final message =
          await Client.getInstance.chatManager.loadMessage(inviteMessageId);
      if (message != null) {
        // ignore: invalid_use_of_protected_member
        ChatUIKit.instance.onMessageUpdate(message);
      }
    }
  }

  void pushToCallPage(
    List<String> userIds,
    ChatCallKitCallType callType,
    String callId, {
    Map<String, String>? ext,
  }) async {
    Widget page;
    String? groupId = ext?['groupId'];
    if (callType == ChatCallKitCallType.multi) {
      page = MultiCallPage.receive(callId, userIds.first, groupId: groupId);
    } else {
      page = SingleCallPage.receive(userIds.first, callId, type: callType);
    }
    [Permission.microphone, Permission.camera].request().then((value) {
      if (mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (context) {
            return page;
          }),
        ).then((value) {
          if (value != null) {
            debugPrint('call end: $value');
          }
        });
      }
    });
  }
}
