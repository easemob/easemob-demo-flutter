import 'package:chat_uikit_demo/demo_localizations.dart';
import 'package:em_chat_uikit/chat_uikit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';

class ToastHandlerWidget extends StatefulWidget {
  const ToastHandlerWidget({required this.child, super.key});
  final Widget child;
  @override
  State<ToastHandlerWidget> createState() => _ToastHandlerWidgetState();
}

class _ToastHandlerWidgetState extends State<ToastHandlerWidget>
    with ChatSDKEventsObserver, ChatUIKitEventsObservers {
  @override
  void initState() {
    super.initState();
    ChatUIKit.instance.addObserver(this);
  }

  @override
  void dispose() {
    ChatUIKit.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }

  @override
  void onChatUIKitEventsReceived(ChatUIKitEvent event) {
    if (event == ChatUIKitEvent.groupIdCopied ||
        event == ChatUIKitEvent.userIdCopied ||
        event == ChatUIKitEvent.messageCopied) {
      EasyLoading.showSuccess(DemoLocalizations.copied.localString(context));
    } else if (event == ChatUIKitEvent.messageDownloading) {
      EasyLoading.showInfo(DemoLocalizations.downloading.localString(context));
    } else if (event == ChatUIKitEvent.noStoragePermission) {
      EasyLoading.showError(
          DemoLocalizations.noStoragePermission.localString(context));
    } else if (event == ChatUIKitEvent.noMicrophonePermission) {
      EasyLoading.showError(
          DemoLocalizations.noMicrophonePermission.localString(context));
    } else if (event == ChatUIKitEvent.noCameraPermission) {
      EasyLoading.showError(
          DemoLocalizations.noCameraPermission.localString(context));
    } else if (event == ChatUIKitEvent.voiceTypeNotSupported) {
      EasyLoading.showError(
          DemoLocalizations.voiceTypeNotSupported.localString(context));
    }
  }

  @override
  void onChatSDKEventBegin(ChatSDKEvent event) {
    if (event == ChatSDKEvent.acceptContactRequest ||
        event == ChatSDKEvent.fetchGroupMemberAttributes ||
        event == ChatSDKEvent.setGroupMemberAttributes ||
        event == ChatSDKEvent.sendContactRequest ||
        event == ChatSDKEvent.changeGroupOwner ||
        event == ChatSDKEvent.declineContactRequest ||
        event == ChatSDKEvent.setSilentMode ||
        event == ChatSDKEvent.createGroup ||
        event == ChatSDKEvent.fetchChatThreadMembers ||
        event == ChatSDKEvent.reportMessage ||
        event == ChatSDKEvent.clearSilentMode ||
        event == ChatSDKEvent.fetchPinnedMessages) {
      EasyLoading.show();
    }
  }

  @override
  void onChatSDKEventEnd(ChatSDKEvent event, ChatError? error) {
    if (event == ChatSDKEvent.acceptContactRequest ||
        event == ChatSDKEvent.fetchGroupMemberAttributes ||
        event == ChatSDKEvent.setGroupMemberAttributes ||
        event == ChatSDKEvent.sendContactRequest ||
        event == ChatSDKEvent.changeGroupOwner ||
        event == ChatSDKEvent.declineContactRequest ||
        event == ChatSDKEvent.setSilentMode ||
        event == ChatSDKEvent.createGroup ||
        event == ChatSDKEvent.clearSilentMode ||
        event == ChatSDKEvent.fetchChatThreadMembers ||
        event == ChatSDKEvent.addReaction ||
        event == ChatSDKEvent.reportMessage ||
        event == ChatSDKEvent.modifyMessage ||
        event == ChatSDKEvent.fetchPinnedMessages) {
      EasyLoading.dismiss();
      if (error != null) {
        EasyLoading.showError(error.description);
      }
    }
  }
}
