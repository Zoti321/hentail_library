import 'package:hentai_library/shared/presentation/providers/catalog_state_providers.dart';
import 'package:hentai_library/shared/presentation/providers/library_reorder_providers.dart';
import 'package:hentai_library/features/library_admin/presentation/library_management_commands.dart';
import 'package:hentai_library/composition/modules/library_admin/library_commands.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/features/library_admin/public.dart';
import 'package:hentai_library/features/library_admin/presentation/view_models/comic_metadata_bulk_patch_controller.dart';
import 'package:hentai_library/features/library_admin/presentation/view_models/library_revision_throttle_busy.dart';
import 'package:hentai_library/features/library_admin/presentation/view_models/metadata_refresh_controller.dart';
import 'package:hentai_library/shared/presentation/providers/library_browse_fallback_providers.dart';
import 'package:riverpod/misc.dart' show Override;

/// library_admin owner：命令工厂与库状态投影（#435）。
List<Override> libraryAdminSharedStateOverrides() => <Override>[
  deleteLibraryCommandProvider.overrideWith(createDeleteLibraryCommand),
  updateLibrarySidebarCommandProvider.overrideWith(
    createUpdateLibrarySidebarCommand,
  ),
  submitLibraryFormCommandProvider.overrideWith(createSubmitLibraryFormCommand),
  exitLibraryReorderCommandProvider.overrideWith(
    createExitLibraryReorderCommand,
  ),
  libraryReorderActiveStateProvider.overrideWith(
    (Ref ref) => ref.watch(libraryReorderModeProvider),
  ),
  bulkEditComicMetadataCommandProvider.overrideWith(
    createBulkEditComicMetadataCommand,
  ),
  startLibraryScanCommandProvider.overrideWith(createStartLibraryScanCommand),
  cancelLibraryScanCommandProvider.overrideWith(createCancelLibraryScanCommand),
  refreshComicMetadataCommandProvider.overrideWith(
    createRefreshComicMetadataCommand,
  ),
  refreshSeriesMetadataCommandProvider.overrideWith(
    createRefreshSeriesMetadataCommand,
  ),
  refreshLibraryMetadataCommandProvider.overrideWith(
    createRefreshLibraryMetadataCommand,
  ),
  cancelMetadataRefreshCommandProvider.overrideWith(
    createCancelMetadataRefreshCommand,
  ),
  libraryManagementCommandsProvider.overrideWith(
    createLibraryManagementCommands,
  ),
  goLibraryBrowseFallbackCommandProvider.overrideWith(
    createGoLibraryBrowseFallbackCommand,
  ),
  librariesStateProvider.overrideWith(
    (Ref ref) => ref.watch(librariesProvider),
  ),
  libraryRevisionStateProvider.overrideWith(
    (Ref ref) => ref.watch(libraryRevisionProvider),
  ),
  libraryRevisionThrottleBusyStateProvider.overrideWith(
    (Ref ref) => ref.watch(libraryRevisionThrottleBusyProvider),
  ),
  libraryMutationBusyStateProvider.overrideWith(
    (Ref ref) =>
        ref.watch(scanLibraryControllerProvider.select((s) => s.running)) ||
        ref.watch(metadataRefreshControllerProvider.select((s) => s.running)) ||
        ref.watch(
          comicMetadataBulkPatchControllerProvider.select((s) => s.running),
        ),
  ),
  libraryScanRunningStateProvider.overrideWith(
    (Ref ref) =>
        ref.watch(scanLibraryControllerProvider.select((s) => s.running)),
  ),
  libraryScanActivityStateProvider.overrideWith((Ref ref) {
    final ScanLibraryState scan = ref.watch(scanLibraryControllerProvider);
    return (running: scan.running, scanMode: scan.scanMode);
  }),
  libraryMetadataRefreshRunningStateProvider.overrideWith(
    (Ref ref) =>
        ref.watch(metadataRefreshControllerProvider.select((s) => s.running)),
  ),
  libraryMetadataRefreshTargetLibraryIdStateProvider.overrideWith(
    (Ref ref) => ref.watch(
      metadataRefreshControllerProvider.select(
        (MetadataRefreshState s) =>
            s.running && s.targetKind == MetadataRefreshTargetKind.library
            ? s.targetId
            : null,
      ),
    ),
  ),
];
