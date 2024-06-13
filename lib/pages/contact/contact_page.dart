import 'package:chat_uikit_demo/custom/demo_helper.dart';
import 'package:chat_uikit_demo/demo_localizations.dart';
import 'package:em_chat_uikit/chat_uikit.dart';
import 'package:flutter/material.dart';

class ContactPage extends StatelessWidget {
  ContactPage({super.key}) {
    // 获取一遍blockList。目的是为了在点开详情时能准确的显示用户是否在黑名单中。
    DemoHelper.fetchBlockList();
  }

  @override
  Widget build(BuildContext context) {
    return ContactsView(
      title: DemoLocalizations.contacts.localString(context),
    );
  }
}
