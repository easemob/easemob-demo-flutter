import 'package:chat_uikit_demo/demo_localizations.dart';
import 'package:chat_uikit_demo/tool/settings_data_store.dart';
import 'package:chat_uikit_demo/widgets/list_item.dart';
import 'package:em_chat_uikit/chat_uikit.dart';
import 'package:flutter/material.dart';

class PrivacyPage extends StatelessWidget {
  const PrivacyPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = ChatUIKitTheme.of(context);
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: theme.color.isDark ? theme.color.neutralColor1 : theme.color.neutralColor98,
      appBar: ChatUIKitAppBar(
        backgroundColor: theme.color.isDark ? theme.color.neutralColor1 : theme.color.neutralColor98,
        centerTitle: false,
        title: DemoLocalizations.secret.localString(context),
      ),
      body: ListView(
        children: [
          if (SettingsDataStore().enableBlockList)
            ListItem(
              title: DemoLocalizations.blockList.localString(context),
              onTap: () => Navigator.of(context).pushNamed('/block_list_page'),
            ),
        ],
      ),
    );
  }
}
