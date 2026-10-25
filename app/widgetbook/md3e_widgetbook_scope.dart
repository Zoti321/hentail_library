import 'package:flutter/material.dart';

/// Viewport chrome for MD3E Widgetbook use cases (theme comes from [md3eWidgetbookAppBuilder]).
class Md3eWidgetbookScope extends StatelessWidget {
  const Md3eWidgetbookScope({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: child);
  }
}
