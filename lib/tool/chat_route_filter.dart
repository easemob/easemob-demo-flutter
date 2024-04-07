import 'package:chat_uikit_demo/demo_localizations.dart';
import 'package:chat_uikit_demo/pages/call/group_member_select_view.dart';
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
    ChatUIKitViewObserver? viewObserver = ChatUIKitViewObserver();
    ContactDetailsViewArguments arguments = settings.arguments as ContactDetailsViewArguments;

    arguments = arguments.copyWith(
      viewObserver: viewObserver,
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
                // 刷新当前页面
                viewObserver.refresh();
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
    }).then((value) {
      viewObserver.refresh();
    }).catchError((e) {});

    return RouteSettings(name: settings.name, arguments: arguments);
  }

  // 为 MessagesView 添加文件点击下载
  static RouteSettings messagesView(RouteSettings settings) {
    MessagesViewArguments arguments = settings.arguments as MessagesViewArguments;
    arguments = arguments.copyWith(
      showMessageItemNickname: (model) {
        // 只有群组消息并且不是自己发的消息显示昵称
        return (arguments.profile.type == ChatUIKitProfileType.group) &&
            model.message.from != ChatUIKit.instance.currentUserId;
      },
      appBarTrailing: Builder(
        builder: (context) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (arguments.profile.type == ChatUIKitProfileType.group)
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: InkWell(
                      highlightColor: Colors.transparent,
                      splashColor: Colors.transparent,
                      onTap: () {
                        ChatUIKitRoute.pushOrPushNamed(
                          context,
                          ChatUIKitRouteNames.threadsView,
                          ThreadsViewArguments(
                            profile: arguments.profile,
                            attributes: arguments.attributes,
                          ),
                        );
                      },
                      child: ChatUIKitImageLoader.messageLongPressThread(),
                    ),
                  ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 24,
                  height: 24,
                  child: InkWell(
                    highlightColor: Colors.transparent,
                    splashColor: Colors.transparent,
                    onTap: () {
                      ChatUIKitColor color = ChatUIKitTheme.of(context).color;
                      // 如果是单聊，弹出选择语音通话和视频通话
                      if (arguments.profile.type == ChatUIKitProfileType.contact) {
                        showChatUIKitBottomSheet(
                          context: context,
                          items: [
                            ChatUIKitBottomSheetItem.normal(
                              icon: Image.asset(
                                'assets/images/voice_call.png',
                                color: color.isDark ? color.primaryColor6 : color.primaryColor5,
                              ),
                              label: DemoLocalizations.voiceCall.localString(context),
                              onTap: () async {
                                Navigator.of(context).pop();
                              },
                            ),
                            ChatUIKitBottomSheetItem.normal(
                              icon: Image.asset(
                                'assets/images/video_call.png',
                                color: color.isDark ? color.primaryColor6 : color.primaryColor5,
                              ),
                              label: DemoLocalizations.videoCall.localString(context),
                              onTap: () async {
                                Navigator.of(context).pop();
                              },
                            ),
                          ],
                        );
                      } else {
                        // 如果是群聊，直接选择联系人
                        Navigator.of(context)
                            .push(
                          MaterialPageRoute(
                            builder: (context) => GroupMemberSelectView(
                              groupId: arguments.profile.id,
                            ),
                          ),
                        )
                            .then((value) {
                          if (value is List<ChatUIKitProfile> && value.isNotEmpty) {
                            debugPrint('start call');
                          }
                        });
                      }
                    },
                    child: Image.asset('assets/images/call.png', fit: BoxFit.fill, width: 24, height: 24),
                  ),
                ),
              ],
            ),
          );
        },
      ),
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
                      profile: ChatUIKitProfile.group(
                        id: group.groupId,
                        groupName: group.name,
                      ),
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
