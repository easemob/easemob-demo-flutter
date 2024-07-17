import 'dart:io';

import 'package:chat_uikit_demo/custom/demo_helper.dart';
import 'package:chat_uikit_demo/demo_localizations.dart';
import 'package:chat_uikit_demo/custom/call_helper.dart';

import 'package:chat_uikit_demo/pages/help/download_page.dart';
import 'package:chat_uikit_demo/tool/app_server_helper.dart';
import 'package:chat_uikit_demo/tool/settings_data_store.dart';
import 'package:chat_uikit_demo/tool/user_data_store.dart';
import 'package:chat_uikit_demo/widgets/presence_icon_status_widget.dart';
import 'package:chat_uikit_demo/widgets/presence_title_widget.dart';

import 'package:em_chat_uikit/chat_uikit.dart';
import 'package:flutter/cupertino.dart';

import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:url_launcher/url_launcher.dart';

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
    } else if (settings.name == ChatUIKitRouteNames.showImageView) {
      return showImageView(settings);
    }
    return settings;
  }

  static RouteSettings showImageView(RouteSettings settings) {
    ShowImageViewArguments arguments =
        settings.arguments as ShowImageViewArguments;
    arguments = arguments.copyWith(
      onLongPressed: (context, message) {
        showChatUIKitBottomSheet(
          context: context,
          items: [
            ChatUIKitBottomSheetAction.normal(
              label: DemoLocalizations.saveImage.localString(context),
              onTap: () async {
                Navigator.of(context).pop();
                File file =
                    File(((message.body) as ImageMessageBody).localPath);
                if (file.existsSync()) {
                  ImageGallerySaver.saveFile(file.path).then((value) => {
                        EasyLoading.showSuccess(DemoLocalizations
                            .saveImageSuccess
                            .localString(context))
                      });
                } else {
                  EasyLoading.showError(
                      DemoLocalizations.saveImageFailed.localString(context));
                }
              },
            ),
          ],
        );
      },
    );
    return RouteSettings(name: settings.name, arguments: arguments);
  }

  static RouteSettings groupDetail(RouteSettings settings) {
    ChatUIKitViewObserver? viewObserver = ChatUIKitViewObserver();
    GroupDetailsViewArguments arguments =
        settings.arguments as GroupDetailsViewArguments;

    arguments = arguments.copyWith(viewObserver: viewObserver);
    // 更新群详情
    Future(() async {
      Group group = await ChatUIKit.instance
          .fetchGroupInfo(groupId: arguments.profile.id);
      ChatUIKitProfile profile = arguments.profile
          .copyWith(name: group.name, avatarUrl: group.extension);
      ChatUIKitProvider.instance.addProfiles([profile]);
      UserDataStore().saveUserData(profile);
    }).catchError((e) {
      debugPrint('fetch group info error');
    });
    return RouteSettings(name: settings.name, arguments: arguments);
  }

  // 自定义 contact detail view
  static RouteSettings contactDetail(RouteSettings settings) {
    ContactDetailsViewArguments arguments =
        settings.arguments as ContactDetailsViewArguments;
    ChatUIKitViewObserver? viewObserver = ChatUIKitViewObserver();
    arguments = arguments.copyWith(
      viewObserver: viewObserver,
      actionsBuilder: (context, defaultList) {
        List<ChatUIKitDetailContentAction> moreActions =
            List.from(defaultList ?? []);
        moreActions.add(
          ChatUIKitDetailContentAction(
            title: DemoLocalizations.voiceCall.localString(context),
            icon: 'assets/images/voice_call.png',
            iconSize: const Size(32, 32),
            onTap: (context) {
              CallHelper.startSingleCall(context, arguments.profile.id, false);
            },
          ),
        );

        moreActions.add(
          ChatUIKitDetailContentAction(
            title: DemoLocalizations.videoCall.localString(context),
            icon: 'assets/images/video_call.png',
            iconSize: const Size(32, 32),
            onTap: (context) {
              CallHelper.startSingleCall(context, arguments.profile.id, true);
            },
          ),
        );
        return moreActions;
      },
      // 添加 remark 实现
      detailsListViewItemsBuilder: (context, profile, defaultItems) {
        return [
          ChatUIKitDetailsListViewItemModel(
            title: DemoLocalizations.contactRemark.localString(context),
            trailing: Text(ChatUIKitProvider.instance
                    .getProfile(arguments.profile)
                    .remark ??
                ''),
            onTap: () async {
              String? remark = await showChatUIKitDialog(
                context: context,
                title: DemoLocalizations.contactRemark.localString(context),
                inputItems: [
                  ChatUIKitDialogInputContentItem(
                    hintText: DemoLocalizations.contactRemarkDesc
                        .localString(context),
                  )
                ],
                actionItems: [
                  ChatUIKitDialogAction.inputsConfirm(
                    label: DemoLocalizations.contactRemarkConfirm
                        .localString(context),
                    onInputsTap: (inputs) async {
                      Navigator.of(context).pop(inputs.first);
                    },
                  ),
                  ChatUIKitDialogAction.cancel(
                      label: DemoLocalizations.contactRemarkCancel
                          .localString(context)),
                ],
              );

              if (remark?.isNotEmpty == true) {
                ChatUIKit.instance
                    .updateContactRemark(arguments.profile.id, remark!)
                    .then((value) {
                  ChatUIKitProfile profile =
                      arguments.profile.copyWith(remark: remark);
                  // 更新数据，并设置到provider中
                  UserDataStore().saveUserData(profile);
                  ChatUIKitProvider.instance.addProfiles([profile]);
                }).catchError((e) {
                  EasyLoading.showError(DemoLocalizations.contactRemarkFailed
                      .localString(context));
                });
              }
            },
          ),
          ...() {
            List<ChatUIKitDetailsListViewItemModel> list = [];
            list.add(defaultItems.first);
            if (SettingsDataStore().enableBlockList) {
              bool isBlocked = DemoHelper.blockList.contains(profile!.id);
              final theme = ChatUIKitTheme.of(context);
              list.add(
                ChatUIKitDetailsListViewItemModel(
                  title: DemoLocalizations.blockContact.localString(context),
                  trailing: CupertinoSwitch(
                    activeColor: theme.color.isDark
                        ? theme.color.primaryColor6
                        : theme.color.primaryColor5,
                    trackColor: theme.color.isDark
                        ? theme.color.neutralColor3
                        : theme.color.neutralColor9,
                    value: isBlocked,
                    onChanged: (value) async {
                      if (isBlocked) {
                        EasyLoading.show();
                        DemoHelper.blockUsers(profile.id, false).then((value) {
                          EasyLoading.showSuccess(
                              DemoLocalizations.unblocked.localString(context));
                          viewObserver.refresh();
                        }).catchError((e) {
                          EasyLoading.showError(DemoLocalizations.unblockFailed
                              .localString(context));
                        }).whenComplete(() {
                          EasyLoading.dismiss();
                        });
                      } else {
                        showChatUIKitDialog(
                            context: context,
                            title: DemoLocalizations.blockContact
                                .localString(context),
                            content:
                                "${DemoLocalizations.blockContent.localString(context)}${profile.showName}?",
                            actionItems: [
                              ChatUIKitDialogAction.cancel(
                                label: DemoLocalizations.blockCancel
                                    .localString(context),
                              ),
                              ChatUIKitDialogAction.confirm(
                                label: DemoLocalizations.blockConfirm
                                    .localString(context),
                                onTap: () async {
                                  Navigator.of(context).pop();
                                  EasyLoading.show();
                                  DemoHelper.blockUsers(profile.id, true)
                                      .then((value) {
                                    EasyLoading.showSuccess(DemoLocalizations
                                        .blocked
                                        .localString(context));
                                    viewObserver.refresh();
                                  }).catchError((e) {
                                    EasyLoading.showError(DemoLocalizations
                                        .blockFailed
                                        .localString(context));
                                  }).whenComplete(() {
                                    EasyLoading.dismiss();
                                  });
                                },
                              ),
                            ]);
                      }
                    },
                  ),
                ),
              );
            }

            list.addAll(defaultItems.sublist(1));
            return list;
          }(),
        ];
      },
    );

    // 异步更新用户信息
    Future(() async {
      String userId = arguments.profile.id;
      try {
        Map<String, UserInfo> map =
            await ChatUIKit.instance.fetchUserInfoByIds([userId]);
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
    MessagesViewArguments arguments =
        settings.arguments as MessagesViewArguments;
    MessagesViewController controller = MessagesViewController(
      profile: arguments.profile,
      searchedMsg: arguments.controller?.searchedMsg,
      willSendHandler: arguments.controller?.willSendHandler,
    );
    arguments = arguments.copyWith(
      controller: controller,
      onItemLongPressHandler: (context, model, defaultActions) {
        if (model.message.attributes?.containsValue('rtcCallWithAgora') ??
            false) {
          return [
            ChatUIKitBottomSheetAction.normal(
              label: DemoLocalizations.multiCallInviteMessageDelete
                  .localString(context),
              onTap: () async {
                Navigator.of(context).pop();
                controller.deleteMessage(model.message.msgId);
              },
            )
          ];
        } else {
          return defaultActions;
        }
      },
      bubbleContentBuilder: (context, model) {
        if (model.message.bodyType == MessageType.TXT) {
          return ChatUIKitTextBubbleWidget(
            model: model,
            onExpTap: (expStr) async {
              if (!expStr.startsWith('http')) {
                expStr = 'https://$expStr';
              }
              await launchUrl(Uri.parse(expStr));
            },
          );
        }

        // 表明是呼叫相关cell
        if (model.message.attributes?.containsValue('rtcCallWithAgora') ??
            false) {
          final theme = ChatUIKitTheme.of(context);
          bool left = model.message.direction == MessageDirection.RECEIVE;
          Color color = left
              ? (theme.color.isDark
                  ? theme.color.neutralColor98
                  : theme.color.neutralColor1)
              : (theme.color.isDark
                  ? theme.color.neutralColor1
                  : theme.color.neutralColor98);
          return InkWell(
            highlightColor: Colors.transparent,
            splashColor: Colors.transparent,
            onTap: () {
              CallHelper.showSingleCallBottomSheet(
                context,
                arguments.profile.id,
                theme.color.isDark
                    ? theme.color.primaryColor6
                    : theme.color.primaryColor5,
              );
            },
            child: Text.rich(
              TextSpan(children: [
                WidgetSpan(
                  child: SizedBox(
                    width: 18,
                    height: 18,
                    child: Image.asset(
                      'assets/images/voice_call.png',
                      color: color,
                    ),
                  ),
                ),
                TextSpan(
                  text: model.message.textContent,
                  style: theme.titleMedium(color: color),
                ),
              ]),
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
      appBarModel: ChatUIKitAppBarModel(
        centerWidget: arguments.profile.type == ChatUIKitProfileType.group
            ? null
            : PresenceTitleWidget(
                userId: arguments.profile.id,
                title: arguments.profile.showName,
              ),
        leadingActionsBuilder: (context, defaultList) {
          if (arguments.profile.type == ChatUIKitProfileType.group) {
            return defaultList;
          }
          if (defaultList?.isNotEmpty == true) {
            for (var i = 0; i < defaultList!.length; i++) {
              ChatUIKitAppBarAction item = defaultList[i];
              if (item.actionType == ChatUIKitActionType.avatar) {
                defaultList[i] = item.copyWith(
                  child: PresenceIconStatusWidget(
                    userId: arguments.profile.id,
                    child: item.child,
                  ),
                );
              }
            }
          }
          return defaultList;
        },
        trailingActionsBuilder: (context, defaultList) {
          List<ChatUIKitAppBarAction>? actions = [];
          if (defaultList?.isNotEmpty == true) {
            actions.addAll(defaultList!);
          }
          ChatUIKitColor color = ChatUIKitTheme.of(context).color;
          if (!controller.isMultiSelectMode) {
            actions.add(
              ChatUIKitAppBarAction(
                onTap: (context) {
                  // 如果是单聊，弹出选择语音通话和视频通话
                  if (arguments.profile.type == ChatUIKitProfileType.contact) {
                    CallHelper.showSingleCallBottomSheet(
                      context,
                      arguments.profile.id,
                      color.isDark ? color.primaryColor6 : color.primaryColor5,
                    );
                  } else {
                    CallHelper.showMultiCallSelectView(
                        context, arguments.profile.id);
                  }
                },
                child: Image.asset(
                  'assets/images/call.png',
                  fit: BoxFit.fill,
                  width: 24,
                  height: 24,
                  color:
                      color.isDark ? color.neutralColor9 : color.neutralColor3,
                ),
              ),
            );
          }

          return actions;
        },
      ),
    );

    return RouteSettings(name: settings.name, arguments: arguments);
  }

  // 添加创建群组拦截，并添加设置群名称功能
  static RouteSettings createGroupView(RouteSettings settings) {
    CreateGroupViewArguments arguments =
        settings.arguments as CreateGroupViewArguments;
    arguments = arguments.copyWith(
      createGroupHandler: (context, selectedProfiles) async {
        String? groupName = await showChatUIKitDialog(
          context: context,
          title: DemoLocalizations.createGroupName.localString(context),
          inputItems: [
            ChatUIKitDialogInputContentItem(
              hintText: DemoLocalizations.createGroupDesc.localString(context),
            )
          ],
          actionItems: [
            ChatUIKitDialogAction.inputsConfirm(
              label: DemoLocalizations.createGroupConfirm.localString(context),
              onInputsTap: (inputs) async {
                Navigator.of(context).pop(inputs.first);
              },
            ),
            ChatUIKitDialogAction.cancel(
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
                  title:
                      DemoLocalizations.createGroupFailed.localString(context),
                  content: error.description,
                  actionItems: [
                    ChatUIKitDialogAction.confirm(
                        label: DemoLocalizations.createGroupConfirm
                            .localString(context)),
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
                          id: group.groupId, groupName: group.name),
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
