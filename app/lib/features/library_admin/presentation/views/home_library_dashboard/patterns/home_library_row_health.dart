import 'package:hentai_library/shared/domain/library/scan_interval.dart';
import 'package:hentai_library/shared/ui/patterns/home/home_library_dashboard_models.dart';

/// 首页库行健康提示（对齐 core `home::classify_sync_alert` 的 stale 启发式）。
///
/// 不含 unreachable / syncFailed：那些依赖 `last_sync_error`，目前不在
/// LocalLibrary 快照上；由 Home alert 区块单独展示。
({HomeLibraryRowHint hint, int? staleDays}) resolveHomeLibraryRowHealth({
  required DateTime now,
  required ScanInterval scanInterval,
  required DateTime? lastSuccessfulSyncAt,
  required int comicCount,
}) {
  final Duration? threshold = scanInterval.period;
  if (threshold == null) {
    return (hint: HomeLibraryRowHint.none, staleDays: null);
  }

  final DateTime? lastSuccess = lastSuccessfulSyncAt;
  if (lastSuccess != null) {
    final Duration elapsed = now.difference(lastSuccess);
    if (elapsed > threshold) {
      return (
        hint: HomeLibraryRowHint.syncWarning,
        staleDays: _staleDaysBetween(lastSuccess, now),
      );
    }
    return (hint: HomeLibraryRowHint.none, staleDays: null);
  }

  if (comicCount > 0) {
    return (hint: HomeLibraryRowHint.syncWarning, staleDays: null);
  }
  return (hint: HomeLibraryRowHint.none, staleDays: null);
}

int _staleDaysBetween(DateTime lastSuccess, DateTime now) {
  final int days = now.difference(lastSuccess).inDays;
  return days < 1 ? 1 : days;
}
