import 'package:hentai_library/shared/ui/patterns/home/home_aggregate_counts.dart';
import 'package:hentai_library/shared/ui/patterns/home/home_library_dashboard_models.dart';

/// Lab 假库 catalog：壳层 Current library、Home 仪表盘、Widgetbook 共用。
abstract final class LabLibraryCatalog {
  static const String defaultLibraryId = 'lab-local-main';

  static final DateTime referenceNow = DateTime(2026, 10, 28, 14, 30);

  static List<HomeLibraryDashboardRow> libraries({DateTime? referenceNow}) {
    final DateTime now = referenceNow ?? LabLibraryCatalog.referenceNow;
    return <HomeLibraryDashboardRow>[
      HomeLibraryDashboardRow(
        libraryId: 'lab-local-main',
        displayName: '本机漫画',
        kind: HomeLibraryKind.local,
        comicCount: 1284,
        seriesCount: 96,
        lastSyncedAt: now.subtract(const Duration(hours: 5, minutes: 12)),
      ),
      HomeLibraryDashboardRow(
        libraryId: 'lab-local-archive',
        displayName: '归档库',
        kind: HomeLibraryKind.local,
        comicCount: 412,
        seriesCount: 38,
        lastSyncedAt: now.subtract(const Duration(days: 2, hours: 3)),
        scanInProgress: true,
      ),
      HomeLibraryDashboardRow(
        libraryId: 'lab-remote-nas',
        displayName: 'NAS WebDAV',
        kind: HomeLibraryKind.remote,
        comicCount: 856,
        seriesCount: 71,
        lastSyncedAt: now.subtract(const Duration(days: 9)),
        hint: HomeLibraryRowHint.syncWarning,
      ),
      HomeLibraryDashboardRow(
        libraryId: 'lab-remote-offline',
        displayName: '离线远程库',
        kind: HomeLibraryKind.remote,
        comicCount: 0,
        seriesCount: 0,
        lastSyncedAt: null,
        hint: HomeLibraryRowHint.unreachable,
      ),
    ];
  }

  static HomeLibraryDashboardRow rowForId(String libraryId) {
    return libraries().firstWhere(
      (HomeLibraryDashboardRow row) => row.libraryId == libraryId,
    );
  }

  static String displayNameForId(String libraryId) =>
      rowForId(libraryId).displayName;

  static HomeAggregateCounts aggregateCounts({DateTime? referenceNow}) {
    final List<HomeLibraryDashboardRow> rows = libraries(
      referenceNow: referenceNow,
    );
    var comicTotal = 0;
    var seriesTotal = 0;
    for (final HomeLibraryDashboardRow row in rows) {
      comicTotal += row.comicCount;
      seriesTotal += row.seriesCount;
    }
    return HomeAggregateCounts(
      comicCount: comicTotal,
      seriesCount: seriesTotal,
      authorCount: 1842,
      parodyCount: 512,
      characterCount: 3289,
      tagCount: 8764,
    );
  }
}
