import 'package:em_chat_uikit/chat_uikit.dart';
import 'package:flutter/widgets.dart';

class DemoHelper {
  static List<String> blockList = [];

  static Future<void> fetchBlockList() async {
    try {
      blockList.clear();
      List<String> list = await ChatUIKit.instance.fetchAllBlockedContactIds();
      blockList.addAll(list);
    } catch (e) {
      debugPrint('fetchBlockList error: $e');
    }
  }

  static Future<void> blockUsers(String userId, bool add) async {
    try {
      if (add) {
        await ChatUIKit.instance.addBlockedContact(userId: userId);
      } else {
        await ChatUIKit.instance.deleteBlockedContact(userId: userId);
      }
      updateBlockList(userId, add);
    } catch (e) {
      debugPrint('blockUsers error: $e');
    }
  }

  static void updateBlockList(String userId, bool add) {
    if (add) {
      blockList.add(userId);
    } else {
      blockList.remove(userId);
    }
  }

  double calculateTextHeight(String text, TextStyle style, double maxWidth) {
    final TextPainter textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: style,
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout(maxWidth: maxWidth);
    return textPainter.size.height;
  }
}
