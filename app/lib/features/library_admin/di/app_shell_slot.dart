/// ADR-0027：library_admin 对 MD3E App shell 的窄插槽实现（bootstrap 经 public re-export 注入）。
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/core/l10n/app_localizations_x.dart';
import 'package:hentai_library/features/library_admin/presentation/views/comic_metadata_bulk_patch_shell_feedback.dart';
import 'package:hentai_library/features/library_admin/presentation/views/library_scan_shell_feedback.dart';
import 'package:hentai_library/features/library_admin/presentation/views/navigation/app_navigation.dart';
import 'package:hentai_library/features/library_admin/presentation/views/navigation/production_shell_adapters.dart';
import 'package:hentai_library/features/library_admin/public/di/library_admin_state_providers.dart';
import 'package:hentai_library/features/home/public/home_library_stat.dart';
import 'package:hentai_library/shared/domain/models/entity/library/local_library.dart';
import 'package:hentai_library/shared/ui/patterns/home/home_library_dashboard_models.dart';
import 'package:hentai_library/design-system/design_system.dart';
import 'package:hentai_library/shared/ui/shell/app_shell_slot.dart';
import 'package:hentai_library/shared/ui/navigation/app_navigator_context.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:hentai_library/features/home/public/di/home_library_stats_stream.dart';

List<Widget> libraryAdminShellFeedbackBelowTitleBar() {
  return const <Widget>[
    LibraryScanShellFeedback(),
    ComicMetadataBulkPatchShellFeedback(),
  ];
}

AppShellNavigationSlot buildLibraryAdminAppShellNavigationSlot(
  BuildContext context,
  WidgetRef ref,
) {
  final String path = appNavigatorOf(context).currentPath();
  final List<LocalLibrary> libraries = ref
      .watch(librariesStateProvider)
      .maybeWhen(
        data: (state) => state.libraries,
        orElse: () => const <LocalLibrary>[],
      );
  final List<HomeLibraryStat> stats = ref
      .watch(homeLibraryStatsStreamProvider)
      .maybeWhen(
        data: (List<HomeLibraryStat> data) => data,
        orElse: () => const <HomeLibraryStat>[],
      );
  final List<HomeLibraryDashboardRow> libraryRows = dashboardRowsForLibraries(
    libraries: libraries,
    stats: stats,
  );
  final M3EColorScheme scheme = M3ETheme.of(context).colorScheme;

  return (
    railDestinations: productionShellRailDestinations(context.l10n),
    libraries: libraryRows,
    selectedNavId: productionSelectedNavId(path: path),
    selectedLibraryId: productionSelectedLibraryId(
      path: path,
      libraries: libraryRows,
    ),
    onNavIdSelected: (String navId) {
      AppNavigation.goToNavId(context, navId, ref: ref);
    },
    onLibrarySelected: (String libraryId) {
      ref.read(libraryManagementPortProvider).openLibrary(context, libraryId);
    },
    surfaceRoles: DesktopShellSurfaceRoles.toneBased(scheme),
  );
}
