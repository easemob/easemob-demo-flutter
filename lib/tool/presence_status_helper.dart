import 'package:em_chat_uikit/chat_uikit.dart';
import 'package:flutter/foundation.dart';

class PresenceStatusHelper {
  static PresenceStatusHelper? _instance;

  factory PresenceStatusHelper() {
    return _instance ??= PresenceStatusHelper._internal();
  }

  PresenceStatusHelper._internal();

  Future<Presence> subscribe(String userId) async {
    List<Presence> presence = await ChatUIKit.instance.subscribe(members: [userId], expiry: 24 * 60 * 60);
    return presence.first;
  }

  void unsubscribe(String userId) async {
    try {
      await ChatUIKit.instance.unsubscribe(members: [userId]);
    } catch (e) {
      debugPrint(e.toString());
    }
  }
}
