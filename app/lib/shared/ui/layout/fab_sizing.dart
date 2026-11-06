import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, TargetPlatform;
import 'package:hentai_library/shared/ui/layout/breakpoints.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

/// 全应用 [M3EFab] 统一响应式尺寸（管理页新建、书库/漫画/系列详情回到顶部等）。
///
/// - 鼠标平台（Windows / macOS / Linux）：小号 FAB 与更小热区；窄窗口仍用 regular。
/// - 触屏平台：按断点 regular / medium / large。
abstract final class FabSizing {
  static M3EFabSize responsive(WindowSizeClass sizeClass) {
    final bool pointerPlatform = switch (defaultTargetPlatform) {
      TargetPlatform.windows ||
      TargetPlatform.macOS ||
      TargetPlatform.linux => true,
      _ => false,
    };
    if (pointerPlatform) {
      return sizeClass.isCompact ? M3EFabSize.regular : M3EFabSize.small;
    }
    return switch (sizeClass) {
      WindowSizeClass.compact || WindowSizeClass.medium => M3EFabSize.regular,
      WindowSizeClass.expanded => M3EFabSize.medium,
      WindowSizeClass.large || WindowSizeClass.extraLarge => M3EFabSize.large,
    };
  }

  /// FAB 容器边长（dp），用于列表底部留白。
  static double containerExtent(M3EFabSize size) {
    return switch (size) {
      M3EFabSize.small => 40,
      M3EFabSize.regular => 56,
      M3EFabSize.medium => 80,
      M3EFabSize.large => 96,
    };
  }
}
