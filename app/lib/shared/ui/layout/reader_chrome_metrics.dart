import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:hentai_library/shared/ui/layout/breakpoints.dart';

/// Lab 阅读器顶/底 chrome 尺寸（沉浸 letterbox + 全宽 scrim）。
///
/// [denseChrome]（expanded+）：键鼠为主，收紧 padding / 图标 / 进度条轨道，
/// 少挡画面；compact/medium 保持触控友好尺寸。
abstract final class ReaderChromeMetrics {
  static const double hideSlidePx = 16;

  /// 触控档默认（compact / medium）。
  static const double edgeGap = 4;
  static const double topBarMinHeight = 48;
  static const double bottomBarMinHeight = 68;
  static const double actionIconSize = 24;
  static const double bottomBarTopPadding = 8;
  static const double progressControlsGap = 2;

  static const double _denseEdgeGap = 2;
  static const double _denseBottomBarMinHeight = 54;
  static const double _denseActionIconSize = 20;
  static const double _denseBottomBarTopPadding = 4;
  static const double _denseProgressControlsGap = 0;
  static const double _denseSliderTrackThickness = 10;
  static const double _denseSliderThumbLength = 32;

  static const double _scrimExtendTop = 96;
  static const double _scrimExtendBottom = 120;

  /// expanded+ 使用更紧凑的 chrome。
  static bool denseChrome(double viewportWidth) {
    return WindowSizeClass.fromWidth(viewportWidth).isAtLeastExpanded;
  }

  static double edgeGapOf(double viewportWidth) =>
      denseChrome(viewportWidth) ? _denseEdgeGap : edgeGap;

  static double bottomBarMinHeightOf(double viewportWidth) => denseChrome(
    viewportWidth,
  )
      ? _denseBottomBarMinHeight
      : bottomBarMinHeight;

  static double bottomBarTopPaddingOf(double viewportWidth) => denseChrome(
    viewportWidth,
  )
      ? _denseBottomBarTopPadding
      : bottomBarTopPadding;

  static double actionIconSizeOf(double viewportWidth) => denseChrome(
    viewportWidth,
  )
      ? _denseActionIconSize
      : actionIconSize;

  static double progressControlsGapOf(double viewportWidth) => denseChrome(
    viewportWidth,
  )
      ? _denseProgressControlsGap
      : progressControlsGap;

  /// 桌面收薄轨道；触控档返回 null 用 M3E xs 默认（16）。
  static double? progressSliderTrackThicknessOf(double viewportWidth) =>
      denseChrome(viewportWidth) ? _denseSliderTrackThickness : null;

  /// 桌面缩短把手；触控档返回 null 用 M3E xs 默认（44）。
  static double? progressSliderThumbLengthOf(double viewportWidth) =>
      denseChrome(viewportWidth) ? _denseSliderThumbLength : null;

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
