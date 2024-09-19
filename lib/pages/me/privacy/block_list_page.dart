import 'package:chat_uikit_demo/demo_localizations.dart';
import 'package:em_chat_uikit/chat_uikit.dart';
import 'package:flutter/material.dart';

class BlockListPage extends StatefulWidget {
  const BlockListPage({super.key});

  @override
  State<BlockListPage> createState() => _BlockListPageState();
}

class _BlockListPageState extends State<BlockListPage> {
  @override
  Widget build(BuildContext context) {
    final theme = ChatUIKitTheme.of(context);
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: theme.color.isDark
          ? theme.color.neutralColor1
          : theme.color.neutralColor98,
      appBar: ChatUIKitAppBar(
        backgroundColor: theme.color.isDark
            ? theme.color.neutralColor1
            : theme.color.neutralColor98,
        centerTitle: false,
        title: DemoLocalizations.blockList.localString(context),
      ),
      body: BlockListView(
        onSearchTap: (data) {
          onSearchTap(context, data);
        },
        onTap: (context, model) => tapContactInfo(model.profile),
      ),
    );
  }

  void onSearchTap(BuildContext context, List<ContactItemModel> data) async {
    List<NeedSearch> list = [];
    for (var item in data) {
      list.add(item);
    }

    Navigator.of(context).push(MaterialPageRoute(
      builder: (context) {
        return SearchView(
          onTap: (ctx, profile) {
            Navigator.of(ctx).pop(profile);
          },
          searchHideText:
              ChatUIKitLocal.conversationsViewSearchHint.localString(context),
          searchData: list,
        );
      },
    )).then((value) {
      if (value != null && value is ChatUIKitProfile) {
        tapContactInfo(value);
      }
    });
  }

  void tapContactInfo(ChatUIKitProfile profile) {
    ChatUIKitRoute.pushOrPushNamed(
        context,
        ChatUIKitRouteNames.contactDetailsView,
        ContactDetailsViewArguments(
          profile: profile,
        )).then((value) {
      ChatUIKit.instance.onConversationsUpdate();
    });
  }
}
