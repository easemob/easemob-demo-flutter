import 'package:em_chat_uikit/chat_uikit.dart';

class DemoHelper {
  static List<String> blockList = [];

  static Future<void> fetchBlockList() async {
    blockList.clear();
    List<String> list = await ChatUIKit.instance.fetchAllBlockedContactIds();
    blockList.addAll(list);
  }

  static Future<void> blockUsers(String userId, bool add) async {
    if (add) {
      await ChatUIKit.instance.addBlockedContact(userId: userId);
    } else {
      await ChatUIKit.instance.deleteBlockedContact(userId: userId);
    }
    updateBlockList(userId, add);
  }

  static void updateBlockList(String userId, bool add) {
    if (add) {
      blockList.add(userId);
    } else {
      blockList.remove(userId);
    }
  }
}
