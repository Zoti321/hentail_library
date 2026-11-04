/// ADR-0027：library_admin 对 MD3E App shell 的窄插槽实现（bootstrap 经 public re-export 注入）。
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hentai_library/core/l10n/app_localizations_x.dart';
import 'package:hentai_library/features/library_admin/presentation/views/comic_metadata_bulk_patch_shell_feedback.dart';
import 'package:hentai_library/features/library_admin/presentation/views/library_scan_shell_feedback.dart';
import 'package:hentai_library/features/library_admin/presentation/views/navigation/app_navigation.dart';
import 'package:hentai_library/features/library_admin/presentation/views/navigation/md3e_production_shell_adapters.dart';
import 'package:hentai_library/shared/di/home_library_stats_providers.dart';
import 'package:hentai_library/shared/di/library_management_providers.dart';
import 'package:hentai_library/shared/di/library_state_providers.dart';
import 'package:hentai_library/shared/domain/library/home_library_stat.dart';
import 'package:hentai_library/shared/domain/models/entity/library/local_library.dart';
import 'package:hentai_library/shared/ui/patterns/home/home_library_dashboard_models.dart';
import 'package:hentai_library/shared/ui/shell/desktop_shell_surfaces.dart';
import 'package:hentai_library/shared/ui/shell/md3e_app_shell_slot.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

/// Shell 标题栏下方、library_admin 负责的反馈插槽（批量元数据条；静默扫描完成 snackbar 监听）。
List<Widget> libraryAdminShellFeedbackBelowTitleBar() {
  return const <Widget>[
    LibraryScanShellFeedback(),
    ComicMetadataBulkPatchShellFeedback(),
  ];
}

/// 组装 MD3E 桌面壳导航槽（rail + 库 flyout）。
Md3eAppShellNavigationSlot buildLibraryAdminMd3eAppShellNavigationSlot(
  BuildContext context,
  WidgetRef ref,
) {
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
