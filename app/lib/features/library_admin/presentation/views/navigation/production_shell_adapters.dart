import 'package:hentai_library/core/constants/libraries_routes.dart';
import 'package:hentai_library/core/l10n/app_localizations.dart';
import 'package:hentai_library/features/library_admin/presentation/views/navigation/app_navigation.dart';
import 'package:hentai_library/shared/domain/models/entity/library/local_library.dart';
import 'package:hentai_library/shared/domain/library/home_library_stat.dart';
import 'package:hentai_library/shared/ui/patterns/home/home_library_dashboard_models.dart';
import 'package:hentai_library/shared/ui/shell/shell_navigation.dart';

List<ShellRailDestination> productionShellRailDestinations(
  AppLocalizations l10n,
) {
  return <ShellRailDestination>[
    ShellRailDestination(
      navId: AppNavigation.navIdHome,
      label: l10n.navHome,
      icon: ShellRailSymbols.home,
    ),
    ShellRailDestination(
      navId: AppNavigation.navIdLibrary,
      label: l10n.libraryTitle,
      icon: ShellRailSymbols.library,
      isLibraryFlyoutAnchor: true,
    ),
    ShellRailDestination(
      navId: AppNavigation.navIdSettings,
      label: l10n.navSettings,
      icon: ShellRailSymbols.settings,
    ),
  ];
}

List<HomeLibraryDashboardRow> dashboardRowsForLibraries({
  required List<LocalLibrary> libraries,
  required List<HomeLibraryStat> stats,
}) {
  final Map<String, HomeLibraryStat> statsById = <String, HomeLibraryStat>{
    for (final HomeLibraryStat stat in stats) stat.libraryId: stat,
  };
  return libraries
      .map((LocalLibrary library) {
        final HomeLibraryStat? stat = statsById[library.libraryId];
        return HomeLibraryDashboardRow(
          libraryId: library.libraryId,
          displayName: localLibraryDisplayName(library),
          kind: isRemoteLibrary(library)
              ? HomeLibraryKind.remote
              : HomeLibraryKind.local,
          comicCount: stat?.comicCount ?? 0,
          seriesCount: stat?.seriesCount ?? 0,
          lastSyncedAt: stat?.lastSuccessfulSyncAt,
        );
      })
      .toList(growable: false);
}

String productionSelectedNavId({required String path}) {
  final String flatNavId = AppNavigation.activeNavIdForPath(path);
  if (flatNavId == AppNavigation.navIdHistory ||
      flatNavId == AppNavigation.navIdTrash ||
      flatNavId == AppNavigation.navIdMetadata) {
    // 管理 / 历史 / 垃圾桶不在 Rail 上；保持无选中目的地。
    return '';
  }
  if (flatNavId.isNotEmpty) {
    return flatNavId;
  }
  if (LibrariesRoutes.libraryIdFromPath(path) != null) {
    return AppNavigation.navIdLibrary;
  }
  if (path.startsWith('/comic/') || path.startsWith('/series/')) {
    return AppNavigation.navIdLibrary;
  }
  return AppNavigation.navIdHome;
}

String productionSelectedLibraryId({
  required String path,
  required List<HomeLibraryDashboardRow> libraries,
}) {
  return librariesSidebarSelectedLibraryId(path: path);
}
