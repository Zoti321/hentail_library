import 'package:flutter/widgets.dart';

const double kSplitListInnerRadius = 4;
const double kSplitListRowGap = 4;

/// 拖拽浮层的外观（颜色、圆角）。由可拖拽分段组注入，行据此绘制浮层背景。
class SplitDragScope extends InheritedWidget {
  const SplitDragScope({
    required this.color,
    required this.radius,
    required super.child,
    super.key,
  });

  final Color color;
  final double radius;

  static SplitDragScope? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<SplitDragScope>();
  }

  @override
  bool updateShouldNotify(SplitDragScope oldWidget) {
    return color != oldWidget.color || radius != oldWidget.radius;
  }
}

