import 'package:em_chat_uikit/chat_uikit.dart';
import 'package:flutter/material.dart';

class ListItem extends StatelessWidget {
  const ListItem({
    required this.title,
    this.subtitle,
    this.imageWidget,
    this.trailingString,
    this.trailingStyle,
    this.trailingWidget,
    this.enableArrow = false,
    this.onTap,
    super.key,
  });

  final Widget? imageWidget;
  final String title;
  final String? subtitle;
  final String? trailingString;
  final TextStyle? trailingStyle;
  final Widget? trailingWidget;
  final bool enableArrow;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = ChatUIKitTheme.of(context);
    Widget content = SizedBox(
      height: 54,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (imageWidget != null)
            SizedBox(
              width: 28,
              height: 28,
              child: imageWidget,
            ),
          if (imageWidget != null) const SizedBox(width: 8),
          Column(
            mainAxisSize: MainAxisSize.max,
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                fit: FlexFit.loose,
                child: Text(
                  title,
                  textScaler: TextScaler.noScaling,
                  style: TextStyle(
                    fontSize: theme.font.titleMedium.fontSize,
                    fontWeight: theme.font.titleMedium.fontWeight,
                    color: theme.color.isDark ? theme.color.neutralColor100 : theme.color.neutralColor1,
                  ),
                ),
              ),
              if (subtitle?.isNotEmpty == true)
                Text(
                  subtitle!,
                  textScaler: TextScaler.noScaling,
                  style: TextStyle(
                    fontSize: theme.font.labelMedium.fontSize,
                    fontWeight: theme.font.labelMedium.fontWeight,
                    color: theme.color.isDark ? theme.color.neutralColor7 : theme.color.neutralColor5,
                  ),
                ),
            ],
          ),
          Expanded(child: Container()),
          if (trailingWidget != null) trailingWidget!,
          if (trailingWidget == null)
            Expanded(
              child: Text(
                trailingString ?? '',
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.right,
                textScaler: TextScaler.noScaling,
                style: trailingStyle ??
                    TextStyle(
                      fontSize: theme.font.labelMedium.fontSize,
                      fontWeight: theme.font.labelMedium.fontWeight,
                      color: theme.color.isDark ? theme.color.neutralColor7 : theme.color.neutralColor5,
                    ),
              ),
            ),
          const SizedBox(width: 4),
          if (enableArrow)
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: theme.color.isDark ? theme.color.neutralColor95 : theme.color.neutralColor3,
            ),
        ],
      ),
    );

    content = Padding(
      padding: const EdgeInsets.only(left: 16, right: 10),
      child: content,
    );

    content = Stack(
      children: [
        content,
        Positioned(
          left: imageWidget != null ? 36 : 16,
          right: 0,
          bottom: 0,
          child: Divider(
            height: 0.5,
            color: theme.color.isDark ? theme.color.neutralColor2 : theme.color.neutralColor9,
          ),
        ),
      ],
    );

    content = InkWell(
      onTap: onTap,
      child: content,
    );

    return content;
  }
}
