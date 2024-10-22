import 'package:chat_uikit_demo/tool/online_status_helper.dart';
import 'package:em_chat_uikit/chat_uikit.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class OnlineIconStatusWidget extends StatefulWidget {
  const OnlineIconStatusWidget({
    required this.child,
    this.onlineStatus = PresenceStatus.none,
    super.key,
  });

  final Widget child;
  final PresenceStatus onlineStatus;

  @override
  State<OnlineIconStatusWidget> createState() => _OnlineIconStatusWidgetState();
}

class _OnlineIconStatusWidgetState extends State<OnlineIconStatusWidget>
    with ChatUIKitThemeMixin {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget themeBuilder(BuildContext context, ChatUIKitTheme theme) {
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
                          color: theme.color.isDark
                              ? theme.color.neutralColor1
                              : theme.color.neutralColor98,
                          borderRadius: BorderRadius.circular(100),
                        ),
                      ),
                    ),
                    Positioned.fill(
                        child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: theme.color.isDark
                              ? theme.color.neutralColor1
                              : theme.color.neutralColor98,
                          width: size,
                        ),
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: () {
                        switch (widget.onlineStatus) {
                          case PresenceStatus.online:
                            return Image.asset(
                                'assets/images/online_online.png');
                          case PresenceStatus.offline:
                            return Image.asset(
                                'assets/images/online_offline.png');
                          case PresenceStatus.away:
                            return Image.asset('assets/images/online_away.png');
                          case PresenceStatus.busy:
                            return Image.asset('assets/images/online_busy.png');
                          case PresenceStatus.notDisturb:
                            return Image.asset('assets/images/online_dnd.png');
                          case PresenceStatus.custom:
                            return Image.asset(
                                'assets/images/online_custom.png');
                          default:
                            return const SizedBox();
                        }
                      }(),
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
