import 'package:em_chat_callkit/chat_callkit.dart';

class CallEndInfo {
  CallEndInfo({
    this.callId,
    required this.callTime,
    required this.remoteUserId,
    required this.reason,
  });
  final String? callId;
  final int callTime;
  final String remoteUserId;
  final ChatCallKitCallEndReason reason;

  @override
  String toString() {
    return 'callTime: $callTime, remoteUserId: $remoteUserId, reason: ${reason.toString()}';
  }
}
