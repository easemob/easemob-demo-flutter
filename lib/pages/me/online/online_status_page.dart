import 'package:em_chat_uikit/chat_uikit.dart';
import 'package:flutter/material.dart';

class OnlineStatusPage extends StatefulWidget {
  const OnlineStatusPage({super.key});

  @override
  State<OnlineStatusPage> createState() => _OnlineStatusPageState();
}

class _OnlineStatusPageState extends State<OnlineStatusPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const ChatUIKitAppBar(
        title: 'Online Status',
      ),
      body: Container(),
    );
  }
}
