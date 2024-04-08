import 'package:flutter/widgets.dart';

class MultiCallView extends StatefulWidget {
  const MultiCallView(this.widgets, {super.key});
  final List<Widget> widgets;
  @override
  State<MultiCallView> createState() => _MultiCallViewState();
}

class _MultiCallViewState extends State<MultiCallView> {
  @override
  Widget build(BuildContext context) {
    List<Widget> list = widget.widgets.map((e) => Expanded(child: e)).toList();

    Widget content;
    if (list.length == 1) {
      content = Column(
        mainAxisSize: MainAxisSize.max,
        children: [list.first],
      );
    } else if (list.length == 2) {
      content = Column(
        mainAxisSize: MainAxisSize.max,
        children: list,
      );
    } else if (list.length == 3) {
      content = Row(children: list.sublist(0, 2));
      content = Column(children: [Expanded(child: content), list.last]);
    } else {
      content = Row(children: list.sublist(0, 2));
      Widget bottom = Row(children: list.sublist(2, 4));
      content = Column(children: [
        Expanded(child: content),
        Expanded(child: bottom),
      ]);
    }
    return content;
  }
}
