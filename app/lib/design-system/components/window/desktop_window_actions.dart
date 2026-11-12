import 'package:flutter/widgets.dart';

/// Host-provided window actions; absent actions leave preview chrome inert.
class DesktopWindowActions extends InheritedWidget {
  const DesktopWindowActions({
    super.key,
    required super.child,
    required this.onMinimize,
    required this.onToggleMaximize,
    required this.onClose,
    required this.onStartDragging,
  });

  final VoidCallback onMinimize;
  final VoidCallback onToggleMaximize;
  final VoidCallback onClose;
  final VoidCallback onStartDragging;

  static DesktopWindowActions? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<DesktopWindowActions>();

  @override
  bool updateShouldNotify(DesktopWindowActions oldWidget) =>
      onMinimize != oldWidget.onMinimize ||
      onToggleMaximize != oldWidget.onToggleMaximize ||
      onClose != oldWidget.onClose ||
      onStartDragging != oldWidget.onStartDragging;
}
