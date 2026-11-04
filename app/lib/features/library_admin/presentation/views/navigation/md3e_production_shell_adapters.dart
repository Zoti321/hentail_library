import 'package:hentai_library/core/constants/libraries_routes.dart';
import 'package:hentai_library/core/l10n/app_localizations.dart';
import 'package:hentai_library/features/library_admin/presentation/views/navigation/app_navigation.dart';
import 'package:hentai_library/shared/domain/models/entity/library/local_library.dart';
import 'package:hentai_library/shared/domain/library/home_library_stat.dart';
import 'package:hentai_library/shared/ui/patterns/home/home_library_dashboard_models.dart';
import 'package:hentai_library/shared/ui/shell/shell_navigation.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// MD3E rail destinations for production（历史 / 垃圾桶入口在首页）。
List<Md3eShellRailDestination> productionMd3eShellRailDestinations(
  AppLocalizations l10n,
) {
  return <Md3eShellRailDestination>[
    Md3eShellRailDestination(
      navId: AppNavigation.navIdHome,
      label: l10n.navHome,
      icon: LucideIcons.house,
      selectedIcon: LucideIcons.house,
    ),
    Md3eShellRailDestination(
      navId: AppNavigation.navIdLibrary,
      label: l10n.libraryTitle,
      icon: LucideIcons.library,
      selectedIcon: LucideIcons.library,
      isLibraryFlyoutAnchor: true,
    ),
    Md3eShellRailDestination(
      navId: AppNavigation.navIdMetadata,
      label: l10n.navMetadata,
      icon: LucideIcons.layers,
      selectedIcon: LucideIcons.layers,
    ),
    Md3eShellRailDestination(
      navId: AppNavigation.navIdSettings,
      label: l10n.navSettings,
      icon: LucideIcons.settings,
      selectedIcon: LucideIcons.settings,
    ),
  ];
}

List<Md3eHomeLibraryDashboardRow> md3eDashboardRowsForLibraries({
  required List<LocalLibrary> libraries,
  required List<HomeLibraryStat> stats,
}) {
  final Map<String, HomeLibraryStat> statsById = <String, HomeLibraryStat>{
    for (final HomeLibraryStat stat in stats) stat.libraryId: stat,
  };
  return libraries
      .map((LocalLibrary library) {
        final HomeLibraryStat? stat = statsById[library.libraryId];
        return Md3eHomeLibraryDashboardRow(
          libraryId: library.libraryId,
          displayName: localLibraryDisplayName(library),
          kind: isRemoteLibrary(library)
              ? Md3eHomeLibraryKind.remote
              : Md3eHomeLibraryKind.local,
          comicCount: stat?.comicCount ?? 0,
          seriesCount: stat?.seriesCount ?? 0,
          lastSyncedAt: stat?.lastSuccessfulSyncAt,
        );
      })
      .toList(growable: false);
}

String productionMd3eSelectedNavId({
  required String path,
  required String? currentLibraryId,
}) {
  final String flatNavId = AppNavigation.activeNavIdForPath(path);
  if (flatNavId == AppNavigation.navIdHistory ||
      flatNavId == AppNavigation.navIdTrash) {
    return AppNavigation.navIdHome;
  }
  if (flatNavId.isNotEmpty) {
    return flatNavId;
  }
  if (LibrariesRoutes.isAllLibrariesPath(path) ||
      LibrariesRoutes.libraryIdFromPath(path) != null) {
    return AppNavigation.navIdLibrary;
  }
  if (path.startsWith('/comic/') || path.startsWith('/series/')) {
    return AppNavigation.navIdLibrary;
  }
  return AppNavigation.navIdHome;
}

String productionMd3eSelectedLibraryId({
  required String path,
  required String? currentLibraryId,
  required List<Md3eHomeLibraryDashboardRow> libraries,
}) {
  final LibrariesSidebarSelection selection = librariesSidebarSelection(
    path: path,
    currentLibraryId: currentLibraryId,
  );
  final String? activeId = selection.activeLibraryId;
  if (activeId != null && activeId.isNotEmpty) {
    return activeId;
  }
  if (currentLibraryId != null && currentLibraryId.isNotEmpty) {
    return currentLibraryId;
  }
  if (libraries.isEmpty) {
    return '';
  }
  return libraries.first.libraryId;
}
