import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/features/library_admin/public.dart';
import 'package:hentai_library/features/library_admin/presentation/view_models/comic_metadata_bulk_patch_controller.dart';
import 'package:hentai_library/features/library_admin/presentation/view_models/library_revision_throttle_busy.dart';
import 'package:hentai_library/features/library_admin/presentation/view_models/metadata_refresh_controller.dart';
import 'package:hentai_library/shared/di/library_command_providers.dart';
import 'package:hentai_library/shared/di/library_management_providers.dart';
import 'package:hentai_library/shared/di/library_state_providers.dart';
import 'package:riverpod/misc.dart' show Override;

/// library_admin owner：Port 工厂与库状态投影（#435）。
List<Override> libraryAdminSharedStateOverrides() => <Override>[
  librariesPortProvider.overrideWith(createLibrariesPort),
  libraryReorderModePortProvider.overrideWith(createLibraryReorderModePort),
  libraryReorderActiveStateProvider.overrideWith(
    (Ref ref) => ref.watch(libraryReorderModeProvider),
  ),
  comicMetadataBulkEditCommandPortProvider.overrideWith(
    createComicMetadataBulkEditCommandPort,
  ),
  libraryScanCommandPortProvider.overrideWith(createLibraryScanCommandPort),
  libraryMetadataRefreshCommandPortProvider.overrideWith(
    createLibraryMetadataRefreshCommandPort,
  ),
  libraryManagementPortProvider.overrideWith(createLibraryManagementPort),
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
