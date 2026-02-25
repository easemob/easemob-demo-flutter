import 'package:chat_uikit_demo/demo_config.dart';
import 'package:chat_uikit_demo/demo_localizations.dart';
import 'package:chat_uikit_demo/pages/call/call_pages/multi_call_page.dart';
import 'package:chat_uikit_demo/pages/call/call_pages/single_call_page.dart';
import 'package:chat_uikit_demo/pages/call/group_member_select_view.dart';
import 'package:em_chat_callkit/chat_callkit.dart';
import 'package:em_chat_uikit/chat_uikit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:permission_handler/permission_handler.dart';

class CallHelper {
  // 弹出 1v1 通话选择框
  static void showSingleCallBottomSheet(
      BuildContext context, String callId, Color color) {
    if (!DemoConfig.isValid) {
      EasyLoading.showError(
          'CallKit is not configured. Please set DemoConfig.');
      return;
    }
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
    if (!DemoConfig.isValid) {
      EasyLoading.showError(
          'CallKit is not configured. Please set DemoConfig.');
      return;
    }
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
    if (!DemoConfig.isValid) {
      EasyLoading.showError(
          'CallKit is not configured. Please set DemoConfig.');
      return;
    }
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

  static String getCallEndReason(BuildContext context, Message message) {
    Map<String, dynamic> ext = Map.from(message.attributes ?? {});
    final raw = ext["call_end_reason"] as int?;
    String callEndReason = (message.body as TextMessageBody?)?.content ?? '';
    if (raw == null) {
      return callEndReason;
    }
    switch (raw) {
      case 0: // hangup
        int? duration = ext["call_duration"] as int?;
        callEndReason = "";
        if (duration != null) {
          // 将秒数转换为时分秒格式
          int hours = duration ~/ 3600;
          int minutes = (duration % 3600) ~/ 60;
          int seconds = duration % 60;
          String formattedDuration =
              '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
          callEndReason =
              ' ${DemoLocalizations.callDuration.localString(context)} $formattedDuration';
        }
        break;
      case 1: // cancel
        callEndReason = DemoLocalizations.callCanceled.localString(context);
        break;
      case 2: // remoteCancel
        callEndReason =
            DemoLocalizations.otherPartyCanceled.localString(context);
        break;
      case 3: // refuse
        callEndReason = DemoLocalizations.refused.localString(context);
        break;
      case 4: // otherPartyRefused
        callEndReason =
            DemoLocalizations.otherPartyRefused.localString(context);
        break;
      case 5: // busy
        callEndReason = DemoLocalizations.otherPartyBusy.localString(context);
        break;
      case 7: // remoteNoResponse
        callEndReason = DemoLocalizations.noResponse.localString(context);
        break;
      case 8: // handleOnOtherDevice
        callEndReason =
            DemoLocalizations.callHandledOnOtherDevice.localString(context);
        break;
      default:
        callEndReason =
            DemoLocalizations.callEndedAbnormally.localString(context);
        break;
    }
    return callEndReason;
  }
}
