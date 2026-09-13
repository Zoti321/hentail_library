import 'package:hentai_library/ui/features/shell/state/metadata_refresh_controller.dart';

/// Library sync 刚结束（running true→false）时，应退出 Series reorder mode。
///
/// 成员集合可能已变；不能用裸 [libraryRevision]（缩略图写入也会 bump）。
bool shouldExitSeriesReorderAfterScan({
  required bool? previousRunning,
  required bool nextRunning,
}) => (previousRunning ?? false) && !nextRunning;

/// 针对本系列或整库的 Metadata refresh 刚结束时，应退出 Series reorder mode。
bool shouldExitSeriesReorderAfterMetadataRefresh({
  required MetadataRefreshState? previous,
  required MetadataRefreshState next,
  required String seriesId,
}) {
  if (previous == null || !previous.running || next.running) {
    return false;
  }
  return switch (previous.targetKind) {
    MetadataRefreshTargetKind.series => previous.targetId == seriesId,
    MetadataRefreshTargetKind.library => true,
    MetadataRefreshTargetKind.comic || null => false,
  };
}
