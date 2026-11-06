import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:hentai_library/shared/ui/layout/breakpoints.dart';
import 'package:hentai_library/shared/ui/layout/spacing.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

/// 漫画 / 系列元数据编辑表单布局 token（Lab）。
/// 页面水平留白统一来自 PageLayoutSpec，本类不再重复定义。
abstract final class MetadataEditFormMetrics {
  static const double comicMaxWidth = 720;
  static const double seriesMaxWidth = 480;
  static const double sideTabColumnWidth = 168;

  /// expanded+ 基础弹窗内容最大宽度（侧栏 + 表单区）。
  static const double expandedDialogContentMaxWidth = 920;

  static const double largeDialogContentMaxWidth = 980;

  static const double extraLargeDialogContentMaxWidth = 1040;

  /// M3E 基础弹窗内容区大致高度（标题 + 操作区 + 内边距）。
  static const double _basicDialogChromeHeight = 196;

  /// 全屏元数据编辑时 header + 安全区预留。
  static const double _fullScreenChromeHeight = 72;

  static double sectionGap(WindowSizeClass sizeClass) {
    return sizeClass.isCompact ? Spacing.space16 : Spacing.space20;
  }

  /// 自适应 [M3EDialog] 内容区最大宽度（expanded+ 更宽）。
  static double dialogContentMaxWidth(BuildContext context) {
    switch (windowSizeClassOf(context)) {
      case WindowSizeClass.expanded:
        return expandedDialogContentMaxWidth;
      case WindowSizeClass.large:
        return largeDialogContentMaxWidth;
      case WindowSizeClass.extraLarge:
        return extraLargeDialogContentMaxWidth;
      case WindowSizeClass.compact:
      case WindowSizeClass.medium:
        return comicMaxWidth;
    }
  }

  /// 对话框外壳 [M3EDialogTheme.maxWidth]（含内边距，须 ≥ 内容宽度）。
  static double dialogShellMaxWidth(BuildContext context) {
    final M3EDialogTheme dialogTheme = M3ETheme.of(context).dialogTheme;
    return dialogContentMaxWidth(context) + dialogTheme.padding.horizontal;
  }

  /// 表单分区滚动的目标高度（expanded+ 占用更多视口）。
  static double dialogContentMaxHeight(BuildContext context) {
    final MediaQueryData media = MediaQuery.of(context);
    final double screenH = media.size.height;
    final bool fullScreen = windowSizeClassOf(context)
        .usesMetadataEditFullScreenRoute;
    if (fullScreen) {
      return math.max(
        280,
        screenH - media.padding.vertical - _fullScreenChromeHeight,
      );
    }
    final WindowSizeClass sizeClass = windowSizeClassOf(context);
    final double heightRatio = switch (sizeClass) {
      WindowSizeClass.expanded => 0.72,
      WindowSizeClass.large => 0.78,
      WindowSizeClass.extraLarge => 0.82,
      WindowSizeClass.compact || WindowSizeClass.medium => 0.55,
    };
    final M3EDialogTheme dialogTheme = M3ETheme.of(context).dialogTheme;
    final double marginVertical = dialogTheme.screenMargin.vertical;
    final double maxFraction = switch (sizeClass) {
      WindowSizeClass.expanded => 0.68,
      WindowSizeClass.large => 0.74,
      WindowSizeClass.extraLarge => 0.78,
      WindowSizeClass.compact || WindowSizeClass.medium => 0.42,
    };
    return (screenH * heightRatio - _basicDialogChromeHeight - marginVertical)
        .clamp(280.0, screenH * maxFraction)
        .toDouble();
  }

  /// 侧栏 + 详情分区滚动用的视口高度。
  ///
  /// [M3EDialog] / [M3EAdaptiveDialog] 的内容在 [SingleChildScrollView] 内，
  /// 子组件常得到竖直方向 unbounded [maxHeight]；此处用屏幕与对话框比例估算可用高度。
  static double resolveTabbedViewportHeight(
    BuildContext context,
    BoxConstraints constraints,
  ) {
    if (constraints.maxHeight.isFinite && constraints.maxHeight > 0) {
      return constraints.maxHeight;
    }
    return dialogContentMaxHeight(context);
  }
}
