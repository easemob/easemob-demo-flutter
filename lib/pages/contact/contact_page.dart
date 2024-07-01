import 'package:chat_uikit_demo/custom/demo_helper.dart';
import 'package:chat_uikit_demo/tool/online_status_helper.dart';
import 'package:chat_uikit_demo/widgets/online_icon_status_widget.dart';
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
      appBarModel: ChatUIKitAppBarModel(
        title: 'Contacts',
        centerTitle: true,
        showBackButton: false,
        leadingActionsBuilder: (context, defaultList) {
          if (defaultList?.isNotEmpty == true) {
            for (var i = 0; i < defaultList!.length; i++) {
              ChatUIKitAppBarAction item = defaultList[i];
              if (item.actionType == ChatUIKitActionType.avatar) {
                defaultList[i] = item.copyWith(
                  child: ValueListenableBuilder(
                    valueListenable: OnlineStatusHelper().onlineStatus,
                    builder: (context, value, child) {
                      return OnlineIconStatusWidget(
                        onlineStatus: value,
                        child: item.child,
                      );
                    },
                    child: OnlineIconStatusWidget(
                      onlineStatus: OnlineStatusHelper().onlineStatus.value,
                      child: item.child,
                    ),
                  ),
                );
              }
            }
          }
          return defaultList;
        },
      ),
    );
  }
}
