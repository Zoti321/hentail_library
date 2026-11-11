import 'package:hentai_library/shared/di/library_management_providers.dart';

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hentai_library/features/library_admin/presentation/views/home_library_dashboard/patterns/home_library_list_order.dart';
import 'package:hentai_library/features/library_admin/presentation/views/home_library_dashboard/patterns/home_library_management_section.dart';
import 'package:hentai_library/features/library_admin/presentation/views/home_library_dashboard/patterns/home_library_row_health.dart';
import 'package:hentai_library/shared/di/home_library_stats_providers.dart';
import 'package:hentai_library/shared/di/library_command_providers.dart';
import 'package:hentai_library/shared/domain/ports/library_management_port.dart';
import 'package:hentai_library/features/library_admin/public/di/library_admin_state_providers.dart';
import 'package:hentai_library/shared/di/library_state_providers.dart';
import 'package:hentai_library/features/library_admin/domain/libraries_state.dart';
import 'package:hentai_library/features/library_admin/domain/library_scan_activity_state.dart';
import 'package:hentai_library/features/library_admin/domain/library_sidebar_layout.dart';
import 'package:hentai_library/features/library_admin/domain/library_metadata_refresh_command_port.dart';
import 'package:hentai_library/features/library_admin/domain/metadata_refresh_types.dart';
import 'package:hentai_library/features/library_admin/domain/sync_library_types.dart';
import 'package:hentai_library/shared/domain/models/entity/library/local_library.dart';
import 'package:hentai_library/features/home/public/home_library_stat.dart';
import 'package:hentai_library/shared/ui/patterns/home/home_library_dashboard_models.dart';
import 'package:hentai_library/shared/ui/widgets/feedback/app_snackbar.dart';
import 'package:hentai_library/shared/ui/widgets/feedback/metadata_refresh_toasts.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// 生产首页「我的漫画库」区块：库列表 UI + 扫描/编辑/排序等编排。
class HomeLibraryManagementPanel extends HookConsumerWidget {
  const HomeLibraryManagementPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final List<HomeLibraryStat> stats = ref
        .watch(homeLibraryStatsStreamProvider)
        .maybeWhen(
          data: (List<HomeLibraryStat> data) => data,
          orElse: () => const <HomeLibraryStat>[],
        );
    final LibrariesState? libraryState = ref
        .watch(librariesStateProvider)
        .asData
        ?.value;
    final List<LocalLibrary> libraries =
        libraryState?.libraries ?? const <LocalLibrary>[];
    final bool scanRunning = ref.watch(
      libraryScanActivityStateProvider.select(
        (LibraryScanActivityState activity) => activity.running,
      ),
    );
    final String? refreshingLibraryId = ref.watch(
      libraryMetadataRefreshTargetLibraryIdStateProvider,
    );

    final ValueNotifier<List<LocalLibrary>?> pendingOrder =
        useState<List<LocalLibrary>?>(null);
    useEffect(() {
      pendingOrder.value = null;
      return null;
    }, <Object?>[libraries]);
    final List<LocalLibrary> ordered = pendingOrder.value ?? libraries;

    final Map<String, HomeLibraryStat> statsById = <String, HomeLibraryStat>{
      for (final HomeLibraryStat stat in stats) stat.libraryId: stat,
    };
    final DateTime now = DateTime.now();
    final List<HomeLibraryDashboardRow> rows = ordered
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
            scanInProgress: scanRunning,
            metadataRefreshInProgress: refreshingLibraryId == library.libraryId,
          );
        })
        .toList(growable: false);

    final Map<String, LocalLibrary> libraryById = <String, LocalLibrary>{
      for (final LocalLibrary library in libraries) library.libraryId: library,
    };

    void handleReorder(int oldIndex, int newIndex) {
      final List<LocalLibrary> next = _pinnedFirst(
        applyHomeLibraryListReorder(ordered, oldIndex, newIndex),
      );
      if (_sameLibraryIds(ordered, next)) {
        return;
      }
      pendingOrder.value = next;
      unawaited(_persistOrder(context, ref, next, pendingOrder));
    }

    void handleAction(String libraryId, HomeLibraryManagementAction action) {
      final LocalLibrary? library = libraryById[libraryId];
      if (library == null) {
        return;
      }
      unawaited(_runLibraryAction(context, ref, library, action));
    }

    final LibraryManagementPort management = ref.read(
      libraryManagementPortProvider,
    );

    return HomeLibraryManagementSection(
      libraries: rows,
      onLibraryOpen: (String libraryId) =>
          unawaited(management.openLibrary(context, libraryId)),
      onLibraryAction: handleAction,
      onAddLocalLibrary: () => unawaited(management.addLocalLibrary(context)),
      onAddRemoteLibrary: () => unawaited(management.addRemoteLibrary(context)),
      onLibrariesReorder: handleReorder,
    );
  }
}

List<LocalLibrary> _pinnedFirst(List<LocalLibrary> libraries) {
  final LibrarySidebarSections sections = splitLibrarySidebar(libraries);
  return <LocalLibrary>[...sections.pinned, ...sections.unpinned];
}

bool _sameLibraryIds(List<LocalLibrary> a, List<LocalLibrary> b) {
  if (a.length != b.length) {
    return false;
  }
  for (int i = 0; i < a.length; i++) {
    if (a[i].libraryId != b[i].libraryId) {
      return false;
    }
  }
  return true;
}

Future<void> _persistOrder(
  BuildContext context,
  WidgetRef ref,
  List<LocalLibrary> next,
  ValueNotifier<List<LocalLibrary>?> pendingOrder,
) async {
  final LibrarySidebarSections sections = splitLibrarySidebar(next);
  try {
    await ref
        .read(librariesPortProvider)
        .updateSidebarLayout(
          encodeLibrarySidebarLayout(
            pinned: sections.pinned,
            unpinned: sections.unpinned,
          ),
        );
  } catch (err) {
    pendingOrder.value = null;
    if (context.mounted) {
      showErrorSnackbar(context, err);
    }
  }
}

Future<void> _runLibraryAction(
  BuildContext context,
  WidgetRef ref,
  LocalLibrary library,
  HomeLibraryManagementAction action,
) async {
  final LibraryManagementPort management = ref.read(
    libraryManagementPortProvider,
  );
  final String libraryId = library.libraryId;
  switch (action) {
    case HomeLibraryManagementAction.scan:
      await management.scanLibrary(context, libraryId);
    case HomeLibraryManagementAction.deepScan:
      await management.scanLibrary(context, libraryId, mode: ScanMode.full);
    case HomeLibraryManagementAction.refreshMetadata:
      final LibraryMetadataRefreshCommandPort refresh = ref.read(
        libraryMetadataRefreshCommandPortProvider,
      );
      if (ref.read(libraryMetadataRefreshTargetLibraryIdStateProvider) ==
          libraryId) {
        refresh.cancel();
        return;
      }
      try {
        final MetadataRefreshBatchResult result = await refresh.refreshLibrary(
          libraryId: libraryId,
          name: localLibraryDisplayName(library),
        );
        if (context.mounted) {
          showMetadataRefreshBatchToast(context, result);
        }
      } catch (err) {
        if (context.mounted) {
          showErrorSnackbar(context, err);
        }
      }
    case HomeLibraryManagementAction.edit:
      await management.editLibrarySettings(context, library);
    case HomeLibraryManagementAction.delete:
      await management.deleteLibrary(context, library);
  }
}
