import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/features/bootstrap/di/deps.dart';
import 'package:hentai_library/features/library_admin/presentation/views/comic_metadata_bulk_patch_shell_feedback.dart';
import 'package:hentai_library/features/library_admin/presentation/views/library_scan_shell_feedback.dart';
import 'package:hentai_library/features/library_admin/presentation/views/navigation/app_navigation.dart';
import 'package:hentai_library/features/library_admin/presentation/views/navigation/libraries_app_sidebar.dart';
import 'package:hentai_library/features/library_admin/presentation/views/navigation/libraries_sidebar_reorder_pane.dart';
import 'package:hentai_library/shared/domain/models/models.dart' show AppSetting;
import 'package:hentai_library/shared/ui/shell/responsive_app_shell.dart';

export 'package:hentai_library/shared/ui/shell/responsive_app_shell.dart'
    show
        ResponsiveAppShell,
        AppShellSidebarBuilder,
        AppShellSidebarSlot,
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
        LibraryScanShellFeedback(),
        ComicMetadataBulkPatchShellFeedback(),
      ],
      sidebarBuilder: (AppShellSidebarSlot slot) => LibrariesAppSidebar(
        slot: slot,
        librariesReorderPaneBuilder: (_) => const LibrariesSidebarReorderPane(),
      ),
    );
  }
}
