import 'package:chat_uikit_demo/demo_localizations.dart';
import 'package:chat_uikit_demo/pages/call/call_pages/multi_call_page.dart';
import 'package:chat_uikit_demo/pages/call/call_pages/single_call_page.dart';
import 'package:chat_uikit_demo/pages/call/group_member_select_view.dart';
import 'package:em_chat_callkit/chat_callkit.dart';
import 'package:em_chat_uikit/chat_uikit.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class CallHelper {
  // 弹出 1v1 通话选择框
  static void showSingleCallBottomSheet(
      BuildContext context, String callId, Color color) {
    showChatUIKitBottomSheet(
      context: context,
      items: [
        ChatUIKitEventAction.normal(
          icon: Image.asset(
            'assets/images/voice_call.png',
            color: color,
          ),
          label: DemoLocalizations.voiceCall.localString(context),
          onTap: () async {
            Navigator.of(context).pop();
            [Permission.microphone, Permission.camera].request().then((value) {
              if (context.mounted) {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) {
                    return SingleCallPage.call(callId,
                        type: ChatCallKitCallType.audio_1v1);
                  }),
                ).then((value) {
                  if (value != null) {
                    debugPrint('call end: $value');
                  }
                });
              }
            });
          },
        ),
        ChatUIKitEventAction.normal(
          icon: Image.asset(
            'assets/images/video_call.png',
            color: color,
          ),
          label: DemoLocalizations.videoCall.localString(context),
          onTap: () async {
            Navigator.of(context).pop();
            [Permission.microphone, Permission.camera].request().then((value) {
              if (context.mounted) {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) {
                    return SingleCallPage.call(callId,
                        type: ChatCallKitCallType.video_1v1);
                  }),
                ).then((value) {
                  if (value != null) {
                    debugPrint('call end: $value');
                  }
                });
              }
            });
          },
        ),
      ],
    );
  }

  // 开始 1v1 通话
  static startSingleCall(
      BuildContext context, String callId, bool isVideoCall) {
    [Permission.microphone, Permission.camera].request().then((value) {
      if (context.mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (context) {
            return SingleCallPage.call(
              callId,
              type: isVideoCall
                  ? ChatCallKitCallType.video_1v1
                  : ChatCallKitCallType.audio_1v1,
            );
          }),
        ).then((value) {
          if (value != null) {
            debugPrint('call end: $value');
          }
        });
      }
    });
  }

  // 弹出多人通话选择框
  static showMultiCallSelectView(BuildContext context, String groupId) {
    // 如果是群聊，直接选择联系人
    Navigator.of(context)
        .push(
      MaterialPageRoute(
        builder: (context) => GroupMemberSelectView(
          groupId: groupId,
        ),
      ),
    )
        .then((value) {
      if (value is List<ChatUIKitProfile> && value.isNotEmpty) {
        List<String> userIds = value.map((e) => e.id).toList();
        [Permission.microphone, Permission.camera].request().then((value) {
          if (context.mounted) {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (context) {
                return MultiCallPage.call(
                  userIds,
                  groupId: groupId,
                );
              }),
            ).then((value) {
              if (value != null) {
                debugPrint('call end: $value');
              }
            });
          }
        });
      }
    });
  }
}
