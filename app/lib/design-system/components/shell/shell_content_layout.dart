import 'package:flutter/widgets.dart';

/// Slot-based chrome and a pane that fills the remaining height.
class ShellContentLayout extends StatelessWidget {
  const ShellContentLayout({
    super.key,
    required this.pane,
    this.titleBar,
    this.feedback = const <Widget>[],
    this.bottomNavigation,
  });

  final Widget pane;
  final Widget? titleBar;
  final List<Widget> feedback;
  final Widget? bottomNavigation;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: <Widget>[
      ?titleBar,
      ...feedback,
      Expanded(child: pane),
      ?bottomNavigation,
    ],
  );
}
