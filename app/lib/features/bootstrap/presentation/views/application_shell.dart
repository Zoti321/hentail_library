import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hentai_library/core/l10n/app_localizations_x.dart';
import 'package:hentai_library/features/bootstrap/di/deps.dart';
import 'package:hentai_library/features/app_settings/presentation/views/widgets/diagnostic_mode_banner.dart';
import 'package:hentai_library/features/library_admin/presentation/views/comic_metadata_bulk_patch_shell_feedback.dart';
import 'package:hentai_library/features/library_admin/presentation/views/library_scan_shell_feedback.dart';
import 'package:hentai_library/features/library_admin/presentation/views/navigation/app_navigation.dart';
import 'package:hentai_library/features/library_admin/presentation/views/navigation/libraries_app_sidebar.dart';
import 'package:hentai_library/features/library_admin/presentation/views/navigation/libraries_sidebar_reorder_pane.dart';
import 'package:hentai_library/features/home/presentation/view_models/home_page_dashboard_notifier.dart';
import 'package:hentai_library/features/library_admin/presentation/views/navigation/md3e_production_shell_adapters.dart';
import 'package:hentai_library/shared/domain/models/models.dart'
    show AppSetting;
import 'package:hentai_library/shared/domain/models/entity/library/local_library.dart';
import 'package:hentai_library/shared/domain/models/read_models/home_page_read_models.dart';
import 'package:hentai_library/shared/di/library_management_providers.dart';
import 'package:hentai_library/shared/di/library_state_providers.dart';
import 'package:hentai_library/shared/ui/patterns/home/home_library_dashboard_models.dart';
import 'package:hentai_library/shared/ui/shell/desktop_shell_surfaces.dart';
import 'package:hentai_library/shared/ui/shell/responsive_app_shell.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

export 'package:hentai_library/shared/ui/shell/responsive_app_shell.dart'
    show
        ResponsiveAppShell,
        AppShellSidebarBuilder,
        AppShellSidebarSlot,
        Md3eAppShellNavigationSlot,
        Md3eAppShellNavigationSlotBuilder,
        openAppShellNavigationDrawer,
        appShellScaffoldKey;

/// Composition root: binds app preferences, navigation, and feature shell slots.
class ApplicationShell extends ConsumerWidget {
  const ApplicationShell({super.key, required this.routeChild});

  final Widget routeChild;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool isSidebarExpandedPref = ref.watch(
      settingsProvider.select(
        (AsyncValue<AppSetting> asyncValue) =>
            asyncValue.asData?.value.desktopSidebarExpanded ?? true,
      ),
    );
    final bool readerFullscreen = ref.watch(readerFullscreenControllerProvider);

    return ResponsiveAppShell(
      routeChild: routeChild,
      activeNavIdForPath: AppNavigation.activeNavIdForPath,
      onNavDestinationSelected: (BuildContext ctx, String id) {
        AppNavigation.goToNavId(ctx, id, ref: ref);
      },
      isDesktopSidebarExpanded: isSidebarExpandedPref,
      onToggleDesktopSidebarExpanded: () {
        ref
            .read(settingsProvider.notifier)
            .setDesktopSidebarExpanded(!isSidebarExpandedPref);
      },
      isReaderFullscreen: readerFullscreen,
      shellFeedbackBelowTitleBar: const <Widget>[
        DiagnosticModeBanner(),
        LibraryScanShellFeedback(),
        ComicMetadataBulkPatchShellFeedback(),
      ],
      sidebarBuilder: (AppShellSidebarSlot slot) => LibrariesAppSidebar(
        slot: slot,
        librariesReorderPaneBuilder: (_) => const LibrariesSidebarReorderPane(),
      ),
      md3eNavigationSlotBuilder: (BuildContext ctx) =>
          _buildMd3eNavigationSlot(context: ctx, ref: ref),
    );
  }
}

Md3eAppShellNavigationSlot _buildMd3eNavigationSlot({
  required BuildContext context,
  required WidgetRef ref,
}) {
  final String path = GoRouterState.of(context).uri.path;
  final List<LocalLibrary> libraries = ref
      .watch(currentLibraryStateProvider)
      .maybeWhen(
        data: (state) => state.libraries,
        orElse: () => const <LocalLibrary>[],
      );
  final String? currentLibraryId = ref
      .watch(currentLibraryStateProvider)
      .maybeWhen(data: (state) => state.currentId, orElse: () => null);
  final List<HomeLibraryStat> stats = ref
      .watch(homeLibraryStatsStreamProvider)
      .maybeWhen(
        data: (List<HomeLibraryStat> data) => data,
        orElse: () => const <HomeLibraryStat>[],
      );
  final List<Md3eHomeLibraryDashboardRow> libraryRows =
      md3eDashboardRowsForLibraries(libraries: libraries, stats: stats);
  final M3EColorScheme scheme = M3ETheme.of(context).colorScheme;

  return (
    railDestinations: productionMd3eShellRailDestinations(context.l10n),
    libraries: libraryRows,
    selectedNavId: productionMd3eSelectedNavId(
      path: path,
      currentLibraryId: currentLibraryId,
    ),
    selectedLibraryId: productionMd3eSelectedLibraryId(
      path: path,
      currentLibraryId: currentLibraryId,
      libraries: libraryRows,
    ),
    onNavIdSelected: (String navId) {
      AppNavigation.goToNavId(context, navId, ref: ref);
    },
    onLibrarySelected: (String libraryId) {
      ref.read(libraryManagementPortProvider).openLibrary(context, libraryId);
    },
    surfaceRoles: Md3eDesktopShellSurfaceRoles.toneBased(scheme),
  );
}
