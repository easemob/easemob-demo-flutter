import 'package:chat_uikit_demo/demo_localizations.dart';
import 'package:em_chat_uikit/chat_uikit.dart';
import 'package:flutter/material.dart';

class TokenStatusHandlerWidget extends StatefulWidget {
  const TokenStatusHandlerWidget({required this.child, super.key});

  final Widget child;

  @override
  State<TokenStatusHandlerWidget> createState() =>
      _TokenStatusHandlerWidgetState();
}

class _TokenStatusHandlerWidgetState extends State<TokenStatusHandlerWidget>
    with ConnectObserver {
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
  void onConnected() {
    debugPrint('onConnected');
  }

  @override
  void onDisconnected() {
    debugPrint('onDisconnected');
  }

  @override
  void onUserDidLoginFromOtherDevice(String deviceName) {
    debugPrint('onUserDidLoginFromOtherDevice: $deviceName');
    showDialogInfo(title: 'Login From Other Device');
  }

  @override
  void onUserDidRemoveFromServer() {
    debugPrint('onUserDidRemoveFromServer');
    showDialogInfo(
        title: 'User Removed', content: 'Please contact the administrator');
  }

  @override
  void onUserDidForbidByServer() {
    debugPrint('onUserDidForbidByServer');
    showDialogInfo(
        title: 'User Forbidden', content: 'Please contact the administrator');
  }

  @override
  void onUserDidChangePassword() {
    debugPrint('onUserDidChangePassword');
    showDialogInfo(title: 'Password Changed', content: 'Please login again');
  }

  @override
  void onUserDidLoginTooManyDevice() {
    debugPrint('onUserDidLoginTooManyDevice');
    showDialogInfo(title: 'LoginTooManyDevice');
  }

  @override
  void onUserKickedByOtherDevice() {
    debugPrint('onUserKickedByOtherDevice');
    showDialogInfo(title: 'KickedByOtherDevice');
  }

  @override
  void onUserAuthenticationFailed() {
    debugPrint('onUserAuthenticationFailed');
    showDialogInfo(
        title: 'Authentication Failed', content: 'Please login again');
  }

  @override
  void onTokenWillExpire() {
    debugPrint('onTokenWillExpire');
  }

  @override
  void onTokenDidExpire() {
    showDialogInfo(title: 'Token Expired', content: 'Please login again');
  }

  void showDialogInfo({
    required String title,
    String? content,
    List<ChatUIKitDialogAction> items = const [],
  }) {
    showChatUIKitDialog(
        context: context,
        title: title,
        content: content,
        actionItems: [
          ChatUIKitDialogAction.confirm(
            label: DemoLocalizations.logoutConfirm.localString(context),
            onTap: () async {
              Navigator.of(context).pop();
              ChatUIKit.instance.logout().then((value) {}).whenComplete(() {
                if (mounted) {
                  Navigator.of(context).popAndPushNamed('/login');
                }
              });
            },
          ),
        ]);
  }

  @override
  void onAppActiveNumberReachLimit() {
    debugPrint('onAppActiveNumberReachLimit');
  }
}
