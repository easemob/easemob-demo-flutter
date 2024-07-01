import 'package:chat_uikit_demo/tool/online_status_helper.dart';
import 'package:chat_uikit_demo/tool/presence_status_helper.dart';
import 'package:em_chat_uikit/chat_uikit.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class PresenceIconStatusWidget extends StatefulWidget {
  const PresenceIconStatusWidget({required this.child, required this.userId, super.key});

  final Widget child;
  final String userId;

  @override
  State<PresenceIconStatusWidget> createState() => _PresenceIconStatusWidgetState();
}

class _PresenceIconStatusWidgetState extends State<PresenceIconStatusWidget> with PresenceObserver {
  final ValueNotifier<PresenceStatus> _onlineStatus = ValueNotifier(PresenceStatus.none);

  @override
  void initState() {
    super.initState();
    ChatUIKit.instance.addObserver(this);
    subscribe();
  }

  void subscribe() async {
    try {
      Presence presence = await PresenceStatusHelper().subscribe(widget.userId);
      _onlineStatus.value = presence.presenceType;
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  @override
  void dispose() {
    ChatUIKit.instance.removeObserver(this);
    PresenceStatusHelper().unsubscribe(widget.userId);
    super.dispose();
  }

  @override
  void onPresenceStatusChanged(List<Presence> list) {
    for (var element in list) {
      if (element.publisher == widget.userId) {
        if (element.statusDescription.isNotEmpty == true) {
          _onlineStatus.value = element.presenceType;
        } else if (element.statusDetails != null) {
          element.statusDetails!.values.any((element) => element == 1)
              ? _onlineStatus.value = PresenceStatus.online
              : _onlineStatus.value = PresenceStatus.offline;
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = ChatUIKitTheme.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.maxHeight / 30.0;
        return Stack(
          children: [
            widget.child,
            Positioned(
              bottom: -size,
              right: -size,
              left: 0,
              top: 0,
              child: FractionallySizedBox(
                alignment: Alignment.bottomRight,
                widthFactor: 0.3,
                heightFactor: 0.3,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          color: theme.color.isDark ? theme.color.neutralColor1 : theme.color.neutralColor98,
                          borderRadius: BorderRadius.circular(100),
                        ),
                      ),
                    ),
                    Positioned.fill(
                        child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: theme.color.isDark ? theme.color.neutralColor1 : theme.color.neutralColor98,
                          width: size,
                        ),
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: ValueListenableBuilder(
                        valueListenable: _onlineStatus,
                        builder: (context, value, child) {
                          return () {
                            switch (value) {
                              case PresenceStatus.online:
                                return Image.asset('assets/images/online_online.png');
                              case PresenceStatus.offline:
                                return Image.asset('assets/images/online_offline.png');
                              case PresenceStatus.away:
                                return Image.asset('assets/images/online_away.png');
                              case PresenceStatus.busy:
                                return Image.asset('assets/images/online_busy.png');
                              case PresenceStatus.notDisturb:
                                return Image.asset('assets/images/online_dnd.png');
                              case PresenceStatus.custom:
                                return Image.asset('assets/images/online_custom.png');
                              default:
                                return const SizedBox();
                            }
                          }();
                        },
                        child: () {
                          switch (_onlineStatus.value) {
                            case PresenceStatus.online:
                              return Image.asset('assets/images/online_online.png');
                            case PresenceStatus.offline:
                              return Image.asset('assets/images/online_offline.png');
                            case PresenceStatus.away:
                              return Image.asset('assets/images/online_away.png');
                            case PresenceStatus.busy:
                              return Image.asset('assets/images/online_busy.png');
                            case PresenceStatus.notDisturb:
                              return Image.asset('assets/images/online_dnd.png');
                            case PresenceStatus.custom:
                              return Image.asset('assets/images/online_custom.png');
                            default:
                              return const SizedBox();
                          }
                        }(),
                      ),
                    )),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
