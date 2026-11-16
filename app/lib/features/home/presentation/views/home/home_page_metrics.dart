import 'package:flutter/widgets.dart';
import 'package:hentai_library/design-system/design_system.dart';

/// [HomeLayout] 间距与内容宽度（对齐生产 Home 与 M3 边距）。
abstract final class HomePageMetrics {
  static double sectionVerticalSpacing(WindowSizeClass sizeClass) {
    return switch (sizeClass) {
      WindowSizeClass.compact => Spacing.space16,
      _ => Spacing.space24,
    };
  }

  static double statCardGap(WindowSizeClass sizeClass) {
    return switch (sizeClass) {
      WindowSizeClass.compact => Spacing.space12,
      _ => Spacing.space16,
    };
  }

  /// Bento 卡片内容与圆角边缘的内边距（大圆角标签卡用 [statTagCardPadding]）。
  static EdgeInsets statCardContentPadding(
    WindowSizeClass sizeClass, {
    bool tagPill = false,
  }) {
    if (tagPill) {
      return switch (sizeClass) {
        WindowSizeClass.compact => const EdgeInsets.fromLTRB(24, 16, 20, 16),
        _ => const EdgeInsets.fromLTRB(32, 18, 28, 18),
      };
    }
    return switch (sizeClass) {
      WindowSizeClass.compact => const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 16,
      ),
      _ => const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
    };
  }

  /// 标签行与上方 bento 行的额外间距（整行宽卡片需要更多留白）。
  static double statTagsRowTopGap(WindowSizeClass sizeClass) {
    return switch (sizeClass) {
      WindowSizeClass.compact => Spacing.space24,
      _ => Spacing.space32,
    };
  }

  static double greetingToSectionSpacing(WindowSizeClass sizeClass) {
    return switch (sizeClass) {
      WindowSizeClass.compact => Spacing.space20,
      _ => Spacing.space28,
    };
  }
}
