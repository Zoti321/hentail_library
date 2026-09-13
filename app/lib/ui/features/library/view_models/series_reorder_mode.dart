import 'package:hentai_library/ui/features/shell/state/library_revision_notifier.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'series_reorder_mode.g.dart';

/// 系列详情页的短暂「Series reorder mode」状态（#121 / ADR-0006）。
///
/// 每个 `seriesId` 独立、非持久；随系列详情页销毁自动复位（autoDispose）。
/// 入口：成员卡长按或 header 溢出菜单「重新排序」→ [enter]。
/// 退出：header 退出控件 → [exit]（并 bump library revision，让普通目录刷新新序）。
/// 外部 Library sync / 本系列(或整库) Metadata refresh 完成时 → [exitForExternalChange]
/// （不重复 bump；勿用裸 libraryRevision，缩略图写入也会 bump）。
@riverpod
class SeriesReorderMode extends _$SeriesReorderMode {
  @override
  bool build(String seriesId) => false;

  void enter() {
    if (!state) {
      state = true;
    }
  }

  /// 用户主动退出：复位并通知 library revision，使普通系列详情目录刷新为新序。
  void exit() {
    if (state) {
      state = false;
      ref.read(libraryRevisionProvider.notifier).notifyExternalChange();
    }
  }

  /// 外部变更（sync/refresh 已自行 bump revision）导致退出：仅复位，不重复 bump。
  void exitForExternalChange() {
    if (state) {
      state = false;
    }
  }
}
