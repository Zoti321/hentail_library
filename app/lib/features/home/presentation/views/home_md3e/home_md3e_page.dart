import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hentai_library/features/home/presentation/view_models/home_facet_counts_provider.dart';
import 'package:hentai_library/features/home/presentation/view_models/home_page_dashboard_notifier.dart';
import 'package:hentai_library/features/home/presentation/views/home_md3e/md3e_home_page.dart';
import 'package:hentai_library/features/home/presentation/views/home_md3e/patterns/md3e_home_library_list_order.dart';
import 'package:hentai_library/features/library_admin/public.dart';
import 'package:hentai_library/shared/domain/library/current_library_state.dart';
import 'package:hentai_library/shared/domain/library/library_scan_activity_state.dart';
import 'package:hentai_library/shared/domain/library/library_sidebar_layout.dart';
import 'package:hentai_library/shared/domain/library/metadata_refresh_types.dart';
import 'package:hentai_library/shared/domain/library/sync_library_types.dart';
import 'package:hentai_library/shared/domain/models/entity/library/local_library.dart';
import 'package:hentai_library/features/home/domain/home_page_read_models.dart';
import 'package:hentai_library/shared/di/library_command_providers.dart';
import 'package:hentai_library/shared/di/library_management_providers.dart';
import 'package:hentai_library/shared/di/library_state_providers.dart';
import 'package:hentai_library/shared/ui/layout/app_shell_navigation.dart';
import 'package:hentai_library/shared/ui/patterns/home/home_aggregate_counts.dart';
import 'package:hentai_library/shared/ui/patterns/home/home_library_dashboard_models.dart';
import 'package:hentai_library/shared/ui/widgets/feedback/custom_toast.dart';
import 'package:hentai_library/shared/ui/widgets/feedback/metadata_refresh_toasts.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// 生产首页入口：把 provider 数据组装为 [Md3eHomePage]，并把库管理动作接到共享端口。
class HomeMd3ePage extends HookConsumerWidget {
  const HomeMd3ePage({super.key});

  static const HomePageCounts _emptyCounts = HomePageCounts(
    comicCount: 0,
    tagCount: 0,
    seriesCount: 0,
    authorCount: 0,
    libraryCount: 0,
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final HomePageCounts counts = ref
        .watch(homePageCountsStreamProvider)
        .maybeWhen(
          data: (HomePageCounts data) => data,
          orElse: () => _emptyCounts,
        );
    final HomeFacetCounts facets = ref
        .watch(homeFacetCountsProvider)
        .maybeWhen(
          data: (HomeFacetCounts data) => data,
          orElse: () => (parodyCount: 0, characterCount: 0),
        );
    final List<HomeLibraryStat> stats = ref
        .watch(homeLibraryStatsStreamProvider)
        .maybeWhen(
          data: (List<HomeLibraryStat> data) => data,
          orElse: () => const <HomeLibraryStat>[],
        );
    final CurrentLibraryState? libraryState = ref
        .watch(currentLibraryStateProvider)
        .asData
        ?.value;
    final List<LocalLibrary> libraries =
        libraryState?.libraries ?? const <LocalLibrary>[];
    final String? currentLibraryId = libraryState?.currentId;
    final bool scanRunning = ref.watch(
      libraryScanActivityStateProvider.select(
        (LibraryScanActivityState activity) => activity.running,
      ),
    );
    final String? refreshingLibraryId = ref.watch(
      libraryMetadataRefreshTargetLibraryIdStateProvider,
    );

    // 拖拽后、持久化回写前的临时顺序；库列表变化后清空，以落库结果为准。
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
    final List<Md3eHomeLibraryDashboardRow> rows = ordered
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
            scanInProgress:
                scanRunning && library.libraryId == currentLibraryId,
            metadataRefreshInProgress: refreshingLibraryId == library.libraryId,
          );
        })
        .toList(growable: false);

    final Map<String, LocalLibrary> libraryById = <String, LocalLibrary>{
      for (final LocalLibrary library in libraries) library.libraryId: library,
    };

    void handleReorder(int oldIndex, int newIndex) {
      final List<LocalLibrary> next = _pinnedFirst(
        applyMd3eHomeLibraryListReorder(ordered, oldIndex, newIndex),
      );
      if (_sameLibraryIds(ordered, next)) {
        return;
      }
      pendingOrder.value = next;
      unawaited(_persistOrder(context, ref, next, pendingOrder));
    }

    void handleAction(
      String libraryId,
      Md3eHomeLibraryManagementAction action,
    ) {
      final LocalLibrary? library = libraryById[libraryId];
      if (library == null) {
        return;
      }
      unawaited(_runLibraryAction(context, ref, library, action));
    }

    return Md3eHomePage(
      libraries: rows,
      aggregateCounts: Md3eHomeAggregateCounts(
        comicCount: counts.comicCount,
        seriesCount: counts.seriesCount,
        authorCount: counts.authorCount,
        parodyCount: facets.parodyCount,
        characterCount: facets.characterCount,
        tagCount: counts.tagCount,
      ),
      onOpenNavigation: appShellPageNavigationOpener(context),
      onLibraryOpen: (String libraryId) => unawaited(
        ref.read(libraryManagementPortProvider).openLibrary(context, libraryId),
      ),
      onLibraryAction: handleAction,
      onAddLocalLibrary: () => unawaited(
        ref.read(libraryManagementPortProvider).addLocalLibrary(context),
      ),
      onAddRemoteLibrary: () => unawaited(
        ref.read(libraryManagementPortProvider).addRemoteLibrary(context),
      ),
      onLibrariesReorder: handleReorder,
    );
  }
}

/// 置顶库在前、非置顶在后；保持各自相对顺序（与侧栏分区一致）。
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
        .read(currentLibraryPortProvider)
        .updateSidebarLayout(
          encodeLibrarySidebarLayout(
            pinned: sections.pinned,
            unpinned: sections.unpinned,
          ),
        );
  } catch (err) {
    pendingOrder.value = null;
    if (context.mounted) {
      showErrorToast(context, err);
    }
  }
}

Future<void> _runLibraryAction(
  BuildContext context,
  WidgetRef ref,
  LocalLibrary library,
  Md3eHomeLibraryManagementAction action,
) async {
  final LibraryManagementPort management = ref.read(
    libraryManagementPortProvider,
  );
  final String libraryId = library.libraryId;
  switch (action) {
    case Md3eHomeLibraryManagementAction.scan:
      await management.scanLibrary(context, libraryId);
    case Md3eHomeLibraryManagementAction.deepScan:
      await management.scanLibrary(context, libraryId, mode: ScanMode.full);
    case Md3eHomeLibraryManagementAction.refreshMetadata:
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
          showErrorToast(context, err);
        }
      }
    case Md3eHomeLibraryManagementAction.edit:
      await management.editLibrarySettings(context, library);
    case Md3eHomeLibraryManagementAction.delete:
      await management.deleteLibrary(context, library);
  }
}
