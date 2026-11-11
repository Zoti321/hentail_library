import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 系列封面槽位入参（仅原始值；禁止 import `features/**`，ADR-0042）。
class SeriesCoverSlotArgs {
  const SeriesCoverSlotArgs({
    required this.seriesId,
    this.fallbackComicId,
    this.priority = 1,
    this.gridIndex,
    this.coverViewportScope,
    this.attachViewportSensor = false,
    this.enableHero = false,
    this.detail = false,
  });

  final String seriesId;

  /// 无自定义系列缩略图时回退的成员漫画 id。
  final String? fallbackComicId;

  /// 缩略图优先级，取值对应 `ThumbnailPriority.values`。
  final int priority;
  final int? gridIndex;
  final String? coverViewportScope;
  final bool attachViewportSensor;
  final bool enableHero;

  /// true = 详情页封面绘制（占位与软裁切样式与卡片不同）。
  final bool detail;
}

/// 系列封面 → Widget（实现归 comic，由 bootstrap 注入）。
typedef SeriesCoverSlot = Widget Function(SeriesCoverSlotArgs args);

/// 系列成员漫画封面槽位入参。
class SeriesMemberCoverSlotArgs {
  const SeriesMemberCoverSlotArgs({
    required this.comicId,
    this.gridIndex,
    this.coverViewportScope,
  });

  final String comicId;
  final int? gridIndex;
  final String? coverViewportScope;
}

/// 系列成员漫画封面 → Widget（实现归 comic）。
typedef SeriesMemberCoverSlot = Widget Function(SeriesMemberCoverSlotArgs args);

/// 系列成员卡只读投影（镜像 `ComicCardProjection` 的原始值形状）。
typedef SeriesMemberCardArgs = ({
  String comicId,
  String title,
  int? pageCount,
  String path,
});

/// 包装系列成员卡：右键菜单/阅读/删除等入口（实现归 comic）。
typedef SeriesMemberCardSlot = Widget Function(
  SeriesMemberCardArgs args,
  Widget child,
);

/// 系列选择模式批量动作（实现归 comic）。
typedef SeriesMemberSelectionActionsSlot = Future<void> Function(
  BuildContext context,
  WidgetRef ref,
  List<String> ids,
);

/// 系列封面状态失效动作（实现归 series；reader 经此触发，不 import series）。
typedef SeriesCoverInvalidationSlot = void Function(String seriesId);
