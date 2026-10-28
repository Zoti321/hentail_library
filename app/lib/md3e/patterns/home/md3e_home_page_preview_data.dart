import 'package:hentai_library/md3e/patterns/home/md3e_home_aggregate_counts.dart';
import 'package:hentai_library/md3e/patterns/home/md3e_home_library_dashboard_models.dart';

/// Widgetbook / Lab 首页预览数据（非生产 FRB）。
abstract final class Md3eHomePagePreviewData {
  static final DateTime _referenceNow = DateTime(2026, 10, 28, 14, 30);

  static List<Md3eHomeLibraryDashboardRow> sampleLibraries({
    DateTime? referenceNow,
  }) =>
      libraries(referenceNow: referenceNow);

  static List<Md3eHomeLibraryDashboardRow> libraries({
    DateTime? referenceNow,
  }) {
    final DateTime now = referenceNow ?? _referenceNow;
    return <Md3eHomeLibraryDashboardRow>[
      Md3eHomeLibraryDashboardRow(
        libraryId: 'lab-local-main',
        displayName: '本机漫画',
        kind: Md3eHomeLibraryKind.local,
        comicCount: 1284,
        seriesCount: 96,
        lastSyncedAt: now.subtract(const Duration(hours: 5, minutes: 12)),
      ),
      Md3eHomeLibraryDashboardRow(
        libraryId: 'lab-local-archive',
        displayName: '归档库',
        kind: Md3eHomeLibraryKind.local,
        comicCount: 412,
        seriesCount: 38,
        lastSyncedAt: now.subtract(const Duration(days: 2, hours: 3)),
        scanInProgress: true,
      ),
      Md3eHomeLibraryDashboardRow(
        libraryId: 'lab-remote-nas',
        displayName: 'NAS WebDAV',
        kind: Md3eHomeLibraryKind.remote,
        comicCount: 856,
        seriesCount: 71,
        lastSyncedAt: now.subtract(const Duration(days: 9)),
        hint: Md3eHomeLibraryRowHint.syncWarning,
      ),
      Md3eHomeLibraryDashboardRow(
        libraryId: 'lab-remote-offline',
        displayName: '离线远程库',
        kind: Md3eHomeLibraryKind.remote,
        comicCount: 0,
        seriesCount: 0,
        lastSyncedAt: null,
        hint: Md3eHomeLibraryRowHint.unreachable,
      ),
    ];
  }

  /// 全库聚合预览（漫画/系列与 sample 库求和一致；元数据维度为 Lab 占位）。
  static Md3eHomeAggregateCounts sampleAggregateCounts() {
    final List<Md3eHomeLibraryDashboardRow> rows = sampleLibraries();
    var comicTotal = 0;
    var seriesTotal = 0;
    for (final Md3eHomeLibraryDashboardRow row in rows) {
      comicTotal += row.comicCount;
      seriesTotal += row.seriesCount;
    }
    return Md3eHomeAggregateCounts(
      comicCount: comicTotal,
      seriesCount: seriesTotal,
      authorCount: 1842,
      parodyCount: 512,
      characterCount: 3289,
      tagCount: 8764,
    );
  }
}
