import 'package:hentai_library/shared/ui/layout/breakpoints.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

/// 全应用 [M3EFab] 尺寸（管理页新建、书库/漫画/系列详情回到顶部等）。
///
/// 对齐 Kazumi 热门页默认 [FloatingActionButton]：固定 regular（56dp），
/// 不随平台或断点缩放为 small / medium / large。
///
/// [sizeClass] 保留给调用方与列表底部留白共用同一解析入口；当前刻意忽略断点。
abstract final class FabSizing {
  static M3EFabSize responsive(WindowSizeClass sizeClass) => M3EFabSize.regular;

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
