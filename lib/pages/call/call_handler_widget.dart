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
  // 本次通话涉及的对端 userId：主叫侧从即将发出的邀请消息取，被叫侧从 onReceiveCall 取。
  // em_chat_callkit 0.0.3 起 onCallEnd 不再回传 ChatCallKitCall（inviteMessageId 已移除），
  // 因此改为记录对端，用对端会话的最新消息刷新通话记录。
  final Set<String> _callPeerIds = <String>{};

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
  void onCallEnd(String? callId, ChatCallKitCallEndReason reason) {
    FlutterRingtonePlayer().stop();
    // 通知消息列表刷新，以显示通话记录消息
    final peerIds = Set<String>.of(_callPeerIds);
    _callPeerIds.clear();
    for (final peerId in peerIds) {
      _updateMessage(peerId);
    }
  }

  // 收到呼叫邀请
  @override
  void onReceiveCall(
    String userId,
    String callId,
    ChatCallKitCallType callType,
    Map<String, String>? ext,
  ) async {
    _callPeerIds.add(userId);

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
    final to = message.to;
    if (to != null) {
      _callPeerIds.add(to);
    }
    // ignore: invalid_use_of_protected_member
    ChatUIKit.instance.onMessagesReceived([message]);
  }

  /// 重新读取 [peerId] 会话的最新消息并刷新到 UI，用于通话结束后显示通话记录。
  Future<void> _updateMessage(String peerId) async {
    final conversation =
        await Client.getInstance.chatManager.getConversation(peerId);
    final message = await conversation?.latestMessage();
    if (message != null) {
      // ignore: invalid_use_of_protected_member
      ChatUIKit.instance.onMessageUpdate(message);
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
