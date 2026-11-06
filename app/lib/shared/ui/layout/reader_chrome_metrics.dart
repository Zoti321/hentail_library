import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:hentai_library/shared/ui/layout/breakpoints.dart';

/// Lab 阅读器顶/底 chrome 尺寸（沉浸 letterbox + 全宽 scrim）。
abstract final class ReaderChromeMetrics {
  static const double edgeGap = 4;
  static const double hideSlidePx = 16;
  static const double topBarMinHeight = 48;
  static const double bottomBarMinHeight = 68;
  static const double actionIconSize = 24;

  static const double _scrimExtendTop = 96;
  static const double _scrimExtendBottom = 120;

  /// 画布左右 letterbox（竖向仍贴顶/底 chrome）。
  static double viewportHorizontalInset(double viewportWidth) {
    return switch (WindowSizeClass.fromWidth(viewportWidth)) {
      WindowSizeClass.compact => 12,
      WindowSizeClass.medium => 16,
      _ => 24,
    };
  }

  /// 底栏内容与画布左对齐时的水平 padding。
  static double chromeContentHorizontalPadding(double viewportWidth) {
    return 12 + viewportHorizontalInset(viewportWidth);
  }

  static double topScrimHeight(MediaQueryData media) =>
      media.padding.top + _scrimExtendTop;

  static double bottomScrimHeight(MediaQueryData media) =>
      media.padding.bottom + _scrimExtendBottom;

  /// 超大屏（≥1600）时顶/底控件行的最大宽度；其余宽度铺满。
  static double chromeContentMaxWidth(double viewportWidth) {
    final WindowSizeClass sizeClass = WindowSizeClass.fromWidth(viewportWidth);
    if (sizeClass != WindowSizeClass.extraLarge) {
      return viewportWidth;
    }
    return (viewportWidth * 0.82).clamp(560.0, 1120.0);
  }

  @Deprecated('Use chromeContentMaxWidth')
  static double targetBarWidth(
    double viewportWidth, {
    double horizontalSafePadding = 0,
  }) {
    final WindowSizeClass sizeClass = WindowSizeClass.fromWidth(viewportWidth);
    if (sizeClass.isCompact) {
      return math.max(0, viewportWidth - horizontalSafePadding);
    }
    return chromeContentMaxWidth(viewportWidth);
  }

  @Deprecated('Immersive chrome is full-bleed scrim')
  static double overlayHorizontalInset(double viewportWidth) => 0;
}
