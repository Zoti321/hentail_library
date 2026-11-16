import 'package:hentai_library/features/home/public/home_library_stat.dart';
import 'package:hentai_library/features/library_admin/presentation/views/home_library_dashboard/patterns/home_library_row_health.dart';
import 'package:hentai_library/features/library_admin/domain/local_library.dart';
import 'package:hentai_library/shared/ui/patterns/home/home_library_dashboard_models.dart';

/// 库 → 首页仪表盘行映射（生产面板与 shell 适配器共用）。
List<HomeLibraryDashboardRow> buildHomeLibraryDashboardRows({
  required List<LocalLibrary> libraries,
  required List<HomeLibraryStat> stats,
  required DateTime now,
  bool scanInProgress = false,
  String? metadataRefreshLibraryId,
}) {
  final Map<String, HomeLibraryStat> statsById = <String, HomeLibraryStat>{
    for (final HomeLibraryStat stat in stats) stat.libraryId: stat,
  };
  return libraries
      .map((LocalLibrary library) {
        final HomeLibraryStat? stat = statsById[library.libraryId];
        final int comicCount = stat?.comicCount ?? 0;
        final DateTime? lastSyncedAt = stat?.lastSuccessfulSyncAt;
        final ({HomeLibraryRowHint hint, int? staleDays}) health =
            resolveHomeLibraryRowHealth(
              now: now,
              scanInterval: library.scanInterval,
              lastSuccessfulSyncAt: lastSyncedAt,
              comicCount: comicCount,
            );
        return HomeLibraryDashboardRow(
          libraryId: library.libraryId,
          displayName: localLibraryDisplayName(library),
          kind: isRemoteLibrary(library)
              ? HomeLibraryKind.remote
              : HomeLibraryKind.local,
          comicCount: comicCount,
          seriesCount: stat?.seriesCount ?? 0,
          lastSyncedAt: lastSyncedAt,
          hint: health.hint,
          staleDays: health.staleDays,
          scanInProgress: scanInProgress,
          metadataRefreshInProgress:
              metadataRefreshLibraryId == library.libraryId,
        );
      })
      .toList(growable: false);
}
