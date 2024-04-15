import 'package:chat_uikit_demo/demo_localizations.dart';
import 'package:em_chat_uikit/chat_uikit.dart';
import 'package:flutter/material.dart';

class ContactPage extends StatelessWidget {
  const ContactPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ContactsView(
      title: DemoLocalizations.contacts.localString(context),
    );
  }
}
