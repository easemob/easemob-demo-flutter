import 'package:chat_uikit_demo/demo_localizations.dart';
import 'package:em_chat_uikit/chat_uikit.dart';
import 'package:flutter/material.dart';

class BlockListPage extends StatelessWidget {
  const BlockListPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = ChatUIKitTheme.of(context);
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: theme.color.isDark ? theme.color.neutralColor1 : theme.color.neutralColor98,
      appBar: ChatUIKitAppBar(
        backgroundColor: theme.color.isDark ? theme.color.neutralColor1 : theme.color.neutralColor98,
        centerTitle: false,
        title: DemoLocalizations.blockList.localString(context),
      ),
      body: BlockListView(
        onSearchTap: (data) {
          onSearchTap(context, data);
        },
        onTap: (context, model) => tapContactInfo(context, model.profile),
      ),
    );
  }

  void onSearchTap(BuildContext context, List<ContactItemModel> data) async {
    List<NeedSearch> list = [];
    for (var item in data) {
      list.add(item);
    }

    ChatUIKitRoute.pushOrPushNamed(
      context,
      ChatUIKitRouteNames.searchUsersView,
      SearchViewArguments(
        onTap: (ctx, profile) {
          Navigator.of(ctx).pop(profile);
        },
        searchHideText: ChatUIKitLocal.conversationsViewSearchHint.localString(context),
        searchData: list,
      ),
    ).then((value) {
      if (value != null && value is ChatUIKitProfile) {
        tapContactInfo(context, value);
      }
    });
  }

  void tapContactInfo(BuildContext context, ChatUIKitProfile profile) {
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
