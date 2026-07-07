import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:hentai_library/ui/core/theme/theme.dart';

/// 阅读器顶/底栏与弹出层的磨砂容器。
class ReaderFloatingPanel extends StatelessWidget {
  const ReaderFloatingPanel({
    super.key,
    required this.child,
    this.width,
    this.constraints,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
  });

  final Widget child;
  final double? width;
  final BoxConstraints? constraints;
  final EdgeInsetsGeometry padding;

  static double targetBarWidth(BuildContext context) {
    final double viewportWidth = MediaQuery.sizeOf(context).width;
    return (viewportWidth * 0.8).clamp(560, 1120).toDouble();
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final double radius = context.tokens.radius.xs;
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          width: width,
          constraints: constraints,
          padding: padding,
          decoration: BoxDecoration(
            color: cs.hentai.readerPanelBackground,
            borderRadius: BorderRadius.circular(radius),
          ),
          child: child,
        ),
      ),
    );
  }
}

/// 阅读器弹出菜单磨砂面板（无阴影、无边框）。
class ReaderFloatingMenuPanel extends StatelessWidget {
  const ReaderFloatingMenuPanel({
    super.key,
    required this.width,
    required this.child,
    this.padding = const EdgeInsets.symmetric(vertical: 6),
  });

  final double width;
  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return ReaderFloatingPanel(width: width, padding: padding, child: child);
  }
}
