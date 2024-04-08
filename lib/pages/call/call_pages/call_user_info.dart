import 'package:flutter/widgets.dart';

typedef CallUserInfoHandler = Future<CallUserInfo> Function(
    String? userId, int? agoraUid);

class CallUserInfo {
  final Widget? avatar;
  final String? nickname;

  CallUserInfo({
    this.avatar,
    this.nickname,
  });
}
