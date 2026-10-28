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
}
