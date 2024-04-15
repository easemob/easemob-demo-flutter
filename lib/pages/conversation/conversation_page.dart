import 'package:chat_uikit_demo/demo_localizations.dart';
import 'package:em_chat_uikit/chat_uikit.dart';
import 'package:flutter/material.dart';

class ConversationPage extends StatelessWidget {
  const ConversationPage({super.key});
  @override
  Widget build(BuildContext context) {
    return ConversationsView(
      title: DemoLocalizations.chat.localString(context),
    );
  }
}
