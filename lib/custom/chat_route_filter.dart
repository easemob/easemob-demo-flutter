import 'package:chat_uikit_demo/demo_localizations.dart';
import 'package:chat_uikit_demo/pages/call/call_helper.dart';

import 'package:chat_uikit_demo/pages/help/download_page.dart';
import 'package:chat_uikit_demo/tool/app_server_helper.dart';
import 'package:chat_uikit_demo/tool/user_data_store.dart';

import 'package:em_chat_uikit/chat_uikit.dart';

import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';

class ChatRouteFilter {
  static RouteSettings chatRouteSettings(RouteSettings settings) {
    // 拦截 ChatUIKitRouteNames.messagesView, 之后对要跳转的页面的 `RouteSettings` 进行自定义，之后返回。
    if (settings.name == ChatUIKitRouteNames.messagesView) {
      return messagesView(settings);
    } else if (settings.name == ChatUIKitRouteNames.createGroupView) {
      return createGroupView(settings);
    } else if (settings.name == ChatUIKitRouteNames.contactDetailsView) {
      return contactDetail(settings);
    } else if (settings.name == ChatUIKitRouteNames.groupDetailsView) {
      return groupDetail(settings);
    }
    return settings;
  }

  static RouteSettings groupDetail(RouteSettings settings) {
    ChatUIKitViewObserver? viewObserver = ChatUIKitViewObserver();
    GroupDetailsViewArguments arguments = settings.arguments as GroupDetailsViewArguments;

    arguments = arguments.copyWith(viewObserver: viewObserver);
    // 更新群详情
    Future(() async {
      Group group = await ChatUIKit.instance.fetchGroupInfo(groupId: arguments.profile.id);
      ChatUIKitProfile profile = arguments.profile.copyWith(name: group.name, avatarUrl: group.extension);
      ChatUIKitProvider.instance.addProfiles([profile]);
      UserDataStore().saveUserData(profile);
    }).then((value) {
      // 刷新ui
      viewObserver.refresh();
    }).catchError((e) {
      debugPrint('fetch group info error');
    });
    return RouteSettings(name: settings.name, arguments: arguments);
  }

  // 自定义 contact detail view
  static RouteSettings contactDetail(RouteSettings settings) {
    ContactDetailsViewArguments arguments = settings.arguments as ContactDetailsViewArguments;
    arguments = arguments.copyWith(
      actionsBuilder: (context) {
        List<ChatUIKitModelAction> moreActions = [];

        moreActions.add(
          ChatUIKitModelAction(
            title: ChatUIKitLocal.contactDetailViewSend.localString(context),
            icon: 'assets/images/chat.png',
            iconSize: const Size(32, 32),
            packageName: ChatUIKitImageLoader.packageName,
            onTap: (ctx) {
              Navigator.of(context).pushNamed(
                ChatUIKitRouteNames.messagesView,
                arguments: MessagesViewArguments(
                  profile: arguments.profile,
                  attributes: arguments.attributes,
                ),
              );
            },
          ),
        );

        moreActions.add(
          ChatUIKitModelAction(
            title: DemoLocalizations.voiceCall.localString(context),
            icon: 'assets/images/voice_call.png',
            iconSize: const Size(32, 32),
            onTap: (context) {
              CallHelper.startSingleCall(context, arguments.profile.id, false);
            },
          ),
        );

        moreActions.add(
          ChatUIKitModelAction(
            title: DemoLocalizations.videoCall.localString(context),
            icon: 'assets/images/video_call.png',
            iconSize: const Size(32, 32),
            onTap: (context) {
              CallHelper.startSingleCall(context, arguments.profile.id, true);
            },
          ),
        );

        moreActions.add(ChatUIKitModelAction(
          title: ChatUIKitLocal.contactDetailViewSearch.localString(context),
          icon: 'assets/images/search_history.png',
          iconSize: const Size(32, 32),
          packageName: ChatUIKitImageLoader.packageName,
          onTap: (context) {
            ChatUIKitRoute.pushOrPushNamed(
              context,
              ChatUIKitRouteNames.searchHistoryView,
              SearchHistoryViewArguments(
                profile: arguments.profile,
                attributes: arguments.attributes,
              ),
            ).then((value) {
              if (value != null && value is Message) {
                ChatUIKitRoute.pushOrPushNamed(
                  context,
                  ChatUIKitRouteNames.messagesView,
                  MessagesViewArguments(
                    profile: arguments.profile,
                    attributes: arguments.attributes,
                    controller: MessageListViewController(
                      profile: arguments.profile,
                      searchedMsg: value,
                    ),
                  ),
                );
              }
            });
          },
        ));

        return moreActions;
      },
      // 添加 remark 实现
      contentWidgetBuilder: (context) {
        return InkWell(
          onTap: () async {
            String? remark = await showChatUIKitDialog(
              context: context,
              title: DemoLocalizations.contactRemark.localString(context),
              hintsText: [DemoLocalizations.contactRemarkDesc.localString(context)],
              items: [
                ChatUIKitDialogItem.inputsConfirm(
                  label: DemoLocalizations.contactRemarkConfirm.localString(context),
                  onInputsTap: (inputs) async {
                    Navigator.of(context).pop(inputs.first);
                  },
                ),
                ChatUIKitDialogItem.cancel(label: DemoLocalizations.contactRemarkCancel.localString(context)),
              ],
            );

            if (remark?.isNotEmpty == true) {
              ChatUIKit.instance.updateContactRemark(arguments.profile.id, remark!).then((value) {
                ChatUIKitProfile profile = arguments.profile.copyWith(remark: remark);
                // 更新数据，并设置到provider中
                UserDataStore().saveUserData(profile);
                ChatUIKitProvider.instance.addProfiles([profile]);
              }).catchError((e) {
                EasyLoading.showError(DemoLocalizations.contactRemarkFailed.localString(context));
              });
            }
          },
          child: ChatUIKitDetailsListViewItem(
            title: DemoLocalizations.contactRemark.localString(context),
            trailing: Text(ChatUIKitProvider.instance.getProfile(arguments.profile).remark ?? ''),
          ),
        );
      },
    );

    // 异步更新用户信息
    Future(() async {
      String userId = arguments.profile.id;
      try {
        Map<String, UserInfo> map = await ChatUIKit.instance.fetchUserInfoByIds([userId]);
        UserInfo? userInfo = map[userId];
        Contact? contact = await ChatUIKit.instance.getContact(userId);
        if (contact != null) {
          ChatUIKitProfile profile = ChatUIKitProfile.contact(
            id: contact.userId,
            nickname: userInfo?.nickName,
            avatarUrl: userInfo?.avatarUrl,
            remark: contact.remark,
          );
          // 更新数据，并设置到provider中
          UserDataStore().saveUserData(profile);
          ChatUIKitProvider.instance.addProfiles([profile]);
        }
      } catch (e) {
        debugPrint('fetch user info error');
      }
    }).catchError((e) {});

    return RouteSettings(name: settings.name, arguments: arguments);
  }

  // 为 MessagesView 添加文件点击下载
  static RouteSettings messagesView(RouteSettings settings) {
    MessagesViewArguments arguments = settings.arguments as MessagesViewArguments;
    MessageListViewController controller = MessageListViewController(profile: arguments.profile);

    arguments = arguments.copyWith(
      controller: controller,
      bubbleContentBuilder: (context, model) {
        // 表明是呼叫相关cell
        if (model.message.attributes?.containsValue('rtcCallWithAgora') ?? false) {
          final theme = ChatUIKitTheme.of(context);
          bool left = model.message.direction == MessageDirection.RECEIVE;
          Color color = left
              ? (theme.color.isDark ? theme.color.neutralColor98 : theme.color.neutralColor1)
              : (theme.color.isDark ? theme.color.neutralColor1 : theme.color.neutralColor98);
          return InkWell(
            highlightColor: Colors.transparent,
            splashColor: Colors.transparent,
            onTap: () {
              CallHelper.showSingleCallBottomSheet(
                context,
                arguments.profile.id,
                theme.color.isDark ? theme.color.primaryColor6 : theme.color.primaryColor5,
              );
            },
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 18,
                  height: 18,
                  child: Image.asset(
                    'assets/images/voice_call.png',
                    color: color,
                  ),
                ),
                Text(model.message.textContent, style: theme.titleMedium(color: color)),
              ],
            ),
          );
        }

        return null;
      },
      showMessageItemNickname: (model) {
        // 只有群组消息并且不是自己发的消息显示昵称
        return (arguments.profile.type == ChatUIKitProfileType.group) &&
            model.message.from != ChatUIKit.instance.currentUserId;
      },
      onItemTap: (ctx, messageModel) {
        if (messageModel.message.bodyType == MessageType.FILE) {
          Navigator.of(ctx).push(
            MaterialPageRoute(
              builder: (context) => DownloadFileWidget(
                message: messageModel.message,
                key: ValueKey(messageModel.message.localTime),
              ),
            ),
          );
          return true;
        }
        return false;
      },
      appBarTrailingActionsBuilder: (context, defaultList) {
        List<ChatUIKitAppBarTrailingAction>? actions = [];
        if (defaultList != null) {
          defaultList.first = defaultList.first.copyWith(
            child: Image.asset('assets/images/topic.png', fit: BoxFit.fill, width: 24, height: 24),
          );
          actions.addAll(defaultList);
        }
        if (!controller.isMultiSelectMode) {
          actions.add(
            ChatUIKitAppBarTrailingAction(
              onTap: (context) {
                ChatUIKitColor color = ChatUIKitTheme.of(context).color;
                // 如果是单聊，弹出选择语音通话和视频通话
                if (arguments.profile.type == ChatUIKitProfileType.contact) {
                  CallHelper.showSingleCallBottomSheet(
                    context,
                    arguments.profile.id,
                    color.isDark ? color.primaryColor6 : color.primaryColor5,
                  );
                } else {
                  CallHelper.showMultiCallSelectView(context, arguments.profile.id);
                }
              },
              child: Image.asset('assets/images/call.png', fit: BoxFit.fill, width: 24, height: 24),
            ),
          );
        }

        return actions;
      },
    );

    return RouteSettings(name: settings.name, arguments: arguments);
  }

  // 添加创建群组拦截，并添加设置群名称功能
  static RouteSettings createGroupView(RouteSettings settings) {
    CreateGroupViewArguments arguments = settings.arguments as CreateGroupViewArguments;
    arguments = arguments.copyWith(
      createGroupHandler: (context, selectedProfiles) async {
        String? groupName = await showChatUIKitDialog(
          context: context,
          title: DemoLocalizations.createGroupName.localString(context),
          hintsText: [DemoLocalizations.createGroupDesc.localString(context)],
          items: [
            ChatUIKitDialogItem.inputsConfirm(
              label: DemoLocalizations.createGroupConfirm.localString(context),
              onInputsTap: (inputs) async {
                Navigator.of(context).pop(inputs.first);
              },
            ),
            ChatUIKitDialogItem.cancel(
              label: DemoLocalizations.createGroupCancel.localString(context),
            ),
          ],
        );

        if (groupName != null) {
          return CreateGroupInfo(
            groupName: groupName,
            onGroupCreateCallback: (group, error) {
              if (error != null) {
                showChatUIKitDialog(
                  context: context,
                  title: DemoLocalizations.createGroupFailed.localString(context),
                  content: error.description,
                  items: [
                    ChatUIKitDialogItem.confirm(label: DemoLocalizations.createGroupConfirm.localString(context)),
                  ],
                );
              } else {
                Navigator.of(context).pop();
                if (group != null) {
                  AppServerHelper.autoDestroyGroup(group.groupId);
                  ChatUIKitRoute.pushOrPushNamed(
                    context,
                    ChatUIKitRouteNames.messagesView,
                    MessagesViewArguments(
                      profile: ChatUIKitProfile.group(id: group.groupId, groupName: group.name),
                    ),
                  );
                }
              }
            },
          );
        } else {
          return null;
        }
      },
    );

    return RouteSettings(name: settings.name, arguments: arguments);
  }
}
