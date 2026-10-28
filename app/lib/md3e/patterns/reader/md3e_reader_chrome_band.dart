import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:hentai_library/md3e/layout/md3e_breakpoints.dart';
import 'package:hentai_library/md3e/layout/md3e_reader_chrome_metrics.dart';
import 'package:hentai_library/md3e/patterns/reader/md3e_reader_chrome_scope.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

enum Md3eReaderChromeBandEdge { top, bottom }

/// 沉浸顶/底 chrome：MD3 半透明 surface + 轻磨砂（非纯黑条）。
class Md3eReaderChromeBand extends StatelessWidget {
  const Md3eReaderChromeBand({
    super.key,
    required this.edge,
    required this.child,
    this.padding,
  });

  final Md3eReaderChromeBandEdge edge;
  final Widget child;
  final EdgeInsetsGeometry? padding;

  static bool _useCenteredContentRail(double viewportWidth) {
    return Md3eWindowSizeClass.fromWidth(viewportWidth) ==
        Md3eWindowSizeClass.extraLarge;
  }

  @override
  Widget build(BuildContext context) {
    final M3EColorScheme scheme = M3ETheme.of(context).colorScheme;
    final bool top = edge == Md3eReaderChromeBandEdge.top;
    final bool reduceMotion = MediaQuery.disableAnimationsOf(context);
    final double viewportWidth = MediaQuery.sizeOf(context).width;
    final Color fill = Md3eReaderImmersiveColors.chromeSurface(scheme);
    final BorderRadius clipRadius = top
        ? BorderRadius.zero
        : const BorderRadius.vertical(
            top: Radius.circular(
              Md3eReaderImmersiveColors.bottomChromeTopRadius,
            ),
          );

    Widget content = Padding(
      padding: padding ?? EdgeInsets.zero,
      child: _layoutContentRail(
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

  static Widget _layoutContentRail({
    required bool top,
    required double viewportWidth,
    required Widget child,
  }) {
    if (!_useCenteredContentRail(viewportWidth)) {
      return child;
    }
    return Align(
      alignment: top ? Alignment.topCenter : Alignment.bottomCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: Md3eReaderChromeMetrics.chromeContentMaxWidth(viewportWidth),
        ),
        child: child,
      ),
    );
  }
}
