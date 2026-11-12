import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:hentai_library/design-system/design_system.dart';
import 'package:hentai_library/shared/ui/layout/reader_chrome_metrics.dart';
import 'package:hentai_library/features/reader/presentation/patterns/reader/reader_chrome_scope.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

enum ReaderChromeBandEdge { top, bottom }

/// 沉浸顶/底 chrome：MD3 半透明 surface + 轻磨砂（非纯黑条）。
class ReaderChromeBand extends StatelessWidget {
  const ReaderChromeBand({
    super.key,
    required this.edge,
    required this.child,
    this.padding,
  });

  final ReaderChromeBandEdge edge;
  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final M3EColorScheme scheme = M3ETheme.of(context).colorScheme;
    final bool top = edge == ReaderChromeBandEdge.top;
    final bool reduceMotion = MediaQuery.disableAnimationsOf(context);
    final double viewportWidth = MediaQuery.sizeOf(context).width;
    final Color fill = ReaderImmersiveColors.chromeSurface(scheme);
    final BorderRadius clipRadius = top
        ? BorderRadius.zero
        : const BorderRadius.vertical(
            top: Radius.circular(ReaderImmersiveColors.bottomChromeTopRadius),
          );

    final Widget content = Padding(
      padding: padding ?? EdgeInsets.zero,
      child: _ReaderContentRail(
        top: top,
        viewportWidth: viewportWidth,
        child: child,
      ),
    );

    Widget surface = DecoratedBox(
      decoration: BoxDecoration(color: fill),
      child: content,
    );

    if (reduceMotion) {
      if (top) {
        return surface;
      }
      return ClipRRect(borderRadius: clipRadius, child: surface);
    }

    return ClipRRect(
      borderRadius: clipRadius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: surface,
      ),
    );
  }
}

class _ReaderContentRail extends StatelessWidget {
  const _ReaderContentRail({
    required this.top,
    required this.viewportWidth,
    required this.child,
  });

  final bool top;
  final double viewportWidth;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (WindowSizeClass.fromWidth(viewportWidth) !=
        WindowSizeClass.extraLarge) {
      return child;
    }
    return Align(
      alignment: top ? Alignment.topCenter : Alignment.bottomCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: ReaderChromeMetrics.chromeContentMaxWidth(viewportWidth),
        ),
        child: child,
      ),
    );
  }
}
