import 'package:chat_uikit_demo/demo_localizations.dart';
import 'package:chat_uikit_demo/tool/login_data_store.dart';
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
  void onDisconnected(int? errorCode, LoginExtensionInfo? info) {
    debugPrint('onDisconnected: $errorCode');
    switch (errorCode) {
      case ChatDisconnectErrorCode.USER_LOGIN_ANOTHER_DEVICE:
        _handleLoggedOut(
          title: 'Login From ${info?.deviceName ?? 'Other Device'}',
        );
        return;
      case ChatDisconnectErrorCode.USER_REMOVED:
        _handleLoggedOut(
          title: 'User Removed',
          content: 'Please contact the administrator',
        );
        return;
      case ChatDisconnectErrorCode.USER_LOGIN_TOO_MANY_DEVICES:
        _handleLoggedOut(title: 'Login Too Many Devices');
        return;
      case ChatDisconnectErrorCode.USER_KICKED_BY_OTHER_DEVICE:
        _handleLoggedOut(title: 'Kicked By Other Device');
        return;
      case ChatDisconnectErrorCode.USER_KICKED_BY_CHANGE_PASSWORD:
        _handleLoggedOut(
          title: 'Login Credential Changed',
          content: 'Please login again',
        );
        return;
      case ChatDisconnectErrorCode.APP_ACTIVE_NUMBER_REACH_LIMITATION:
        _handleLoggedOut(title: 'App Active Number Reached Limit');
        return;
      case ChatDisconnectErrorCode.SERVER_SERVICE_RESTRICTED:
        _handleLoggedOut(
          title: 'Service Restricted',
          content: 'Please contact the administrator',
        );
        return;
      case ChatDisconnectErrorCode.INVALID_TOKEN:
      case ChatDisconnectErrorCode.INVALID_PARAM:
      case ChatDisconnectErrorCode.USER_NOT_FOUND:
      case ChatDisconnectErrorCode.USER_BIND_ANOTHER_DEVICE:
      case ChatDisconnectErrorCode.USER_DEVICE_CHANGED:
      case ChatDisconnectErrorCode.SERVER_GET_DNSLIST_FAILED:
        _handleLoggedOut(
          title: 'Authentication Failed',
          content: 'Please login again',
        );
        return;
      default:
        return;
    }
  }

  @override
  void onTokenWillExpire() {
    debugPrint('onTokenWillExpire');
  }

  @override
  void onTokenDidExpire() {
    _handleLoggedOut(title: 'Token Expired', content: 'Please login again');
  }

  void _handleLoggedOut({required String title, String? content}) async {
    await LoginDataStore.clear();
    if (!mounted) return;
    showDialogInfo(title: title, content: content);
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
                  Navigator.of(context).pushNamedAndRemoveUntil(
                    '/login',
                    (route) => false,
                  );
                }
              });
            },
          ),
        ]);
  }
}
