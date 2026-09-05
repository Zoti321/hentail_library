import 'package:flutter/widgets.dart';

/// Propagates reader viewport scroll activity to page image widgets (P2-1).
class ReaderScrollActivity extends InheritedWidget {
  const ReaderScrollActivity({
    super.key,
    required this.isScrolling,
    required super.child,
  });

  final bool isScrolling;

  static bool isScrollingOf(BuildContext context) {
    return context
            .dependOnInheritedWidgetOfExactType<ReaderScrollActivity>()
            ?.isScrolling ??
        false;
  }

  @override
  bool updateShouldNotify(ReaderScrollActivity oldWidget) {
    return isScrolling != oldWidget.isScrolling;
  }
}
