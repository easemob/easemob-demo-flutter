import 'package:chat_uikit_demo/tool/online_status_helper.dart';
import 'package:chat_uikit_demo/tool/presence_status_helper.dart';
import 'package:em_chat_uikit/chat_uikit.dart';
import 'package:flutter/material.dart';

class PresenceTitleWidget extends StatefulWidget {
  const PresenceTitleWidget({
    required this.userId,
    required this.title,
    super.key,
  });

  final String userId;
  final String title;

  @override
  State<PresenceTitleWidget> createState() => _PresenceTitleWidgetState();
}

class _PresenceTitleWidgetState extends State<PresenceTitleWidget>
    with PresenceObserver, ChatUIKitThemeMixin {
  Presence? _presence;

  @override
  void initState() {
    super.initState();
    ChatUIKit.instance.addObserver(this);
    subscribe();
  }

  @override
  void dispose() {
    ChatUIKit.instance.removeObserver(this);
    PresenceStatusHelper().unsubscribe(widget.userId);
    super.dispose();
  }

  void subscribe() async {
    try {
      Presence presence = await PresenceStatusHelper().subscribe(widget.userId);
      _presence = presence;
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  @override
  void onPresenceStatusChanged(List<Presence> list) {
    for (var element in list) {
      if (element.publisher == widget.userId) {
        _presence = element;
        setState(() {});
      }
    }
  }

  @override
  Widget themeBuilder(BuildContext context, ChatUIKitTheme theme) {
    return SizedBox(
      height: 40,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            widget.title,
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
            textScaler: TextScaler.noScaling,
            style: TextStyle(
              fontSize: theme.font.titleMedium.fontSize,
              fontWeight: theme.font.titleMedium.fontWeight,
              color: theme.color.isDark
                  ? theme.color.neutralColor98
                  : theme.color.neutralColor1,
            ),
          ),
          _presence != null
              ? Text(
                  _presence!.presenceStr(),
                  textScaler: TextScaler.noScaling,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  style: TextStyle(
                    fontSize: theme.font.bodyExtraSmall.fontSize,
                    fontWeight: theme.font.bodyExtraSmall.fontWeight,
                    color: theme.color.isDark
                        ? theme.color.neutralColor6
                        : theme.color.neutralColor5,
                  ),
                )
              : const SizedBox(),
        ],
      ),
    );
  }
}
