import 'package:flutter/material.dart';

class CallButton extends StatefulWidget {
  const CallButton({
    required this.callback,
    required this.selected,
    required this.selectImage,
    this.unselectImage,
    this.backgroundColor,
    super.key,
  });

  final VoidCallback callback;
  final bool selected;
  final Widget selectImage;
  final Widget? unselectImage;
  final Color? backgroundColor;
  @override
  State<CallButton> createState() => _CallButtonState();
}

class _CallButtonState extends State<CallButton> {
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: widget.callback,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(50),
          color: widget.backgroundColor ??
              (widget.selected
                  ? const Color.fromRGBO(255, 255, 255, 1)
                  : const Color.fromRGBO(255, 255, 255, 0.2)),
        ),
        width: 64,
        height: 64,
        child: widget.selected
            ? widget.selectImage
            : widget.unselectImage ?? widget.selectImage,
      ),
    );
  }
}
