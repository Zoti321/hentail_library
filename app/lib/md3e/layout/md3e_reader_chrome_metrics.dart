import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:hentai_library/md3e/layout/md3e_breakpoints.dart';

/// Lab 阅读器顶/底 chrome 尺寸（沉浸 letterbox + 全宽 scrim）。
abstract final class Md3eReaderChromeMetrics {
  static const double edgeGap = 4;
  static const double hideSlideFraction = 0.12;
  static const double topBarMinHeight = 48;
  static const double bottomBarMinHeight = 68;
  static const double actionIconSize = 24;

  static const double _scrimExtendTop = 96;
  static const double _scrimExtendBottom = 120;

  /// 画布左右 letterbox（竖向仍贴顶/底 chrome）。
  static double viewportHorizontalInset(double viewportWidth) {
    final Md3eWindowSizeClass sizeClass =
        Md3eWindowSizeClass.fromWidth(viewportWidth);
    return sizeClass.isCompact ? edgeGap : 12;
  }

  static double topScrimHeight(MediaQueryData media) =>
      media.padding.top + _scrimExtendTop;

  static double bottomScrimHeight(MediaQueryData media) =>
      media.padding.bottom + _scrimExtendBottom;

  /// 宽屏下控件行最大宽度；紧凑屏铺满。
  static double chromeContentMaxWidth(double viewportWidth) {
    final Md3eWindowSizeClass sizeClass =
        Md3eWindowSizeClass.fromWidth(viewportWidth);
    if (sizeClass.isCompact) {
      return viewportWidth;
    }
    return (viewportWidth * 0.82).clamp(560.0, 1120.0);
  }

  @Deprecated('Use chromeContentMaxWidth')
  static double targetBarWidth(
    double viewportWidth, {
    double horizontalSafePadding = 0,
  }) {
    final Md3eWindowSizeClass sizeClass =
        Md3eWindowSizeClass.fromWidth(viewportWidth);
    if (sizeClass.isCompact) {
      return math.max(0, viewportWidth - horizontalSafePadding);
    }
    return chromeContentMaxWidth(viewportWidth);
  }

  @Deprecated('Immersive chrome is full-bleed scrim')
  static double overlayHorizontalInset(double viewportWidth) => 0;
}
