import 'package:hentai_library/features/library_admin/presentation/view_models/comic_metadata_bulk_patch_controller.dart';
import 'package:hentai_library/features/library_admin/presentation/view_models/metadata_refresh_controller.dart';
import 'package:hentai_library/features/library_admin/presentation/view_models/scan_library_controller.dart';
import 'package:hentai_library/features/library_admin/domain/library_metadata_refresh_commands.dart';
import 'package:hentai_library/features/library_admin/domain/library_scan_commands.dart';
import 'package:hentai_library/features/library_admin/domain/sync_library_types.dart';
import 'package:hentai_library/features/library_admin/presentation/view_models/libraries_notifier.dart';
import 'package:hentai_library/features/library_admin/presentation/view_models/library_reorder_mode_notifier.dart';
import 'package:hentai_library/features/library_admin/domain/bulk_edit_comic_metadata_command.dart';
import 'package:hentai_library/features/library_admin/domain/library_commands.dart';
import 'package:hentai_library/shared/domain/contracts/exit_library_reorder_command.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

DeleteLibraryCommand createDeleteLibraryCommand(Ref ref) =>
    (id) => ref.read(librariesProvider.notifier).deleteLibrary(id);
UpdateLibrarySidebarCommand createUpdateLibrarySidebarCommand(Ref ref) =>
    (placements) =>
        ref.read(librariesProvider.notifier).updateSidebarLayout(placements);
SubmitLibraryFormCommand createSubmitLibraryFormCommand(Ref ref) =>
    (form, {original}) => ref
        .read(librariesProvider.notifier)
        .submitLibraryForm(form, original: original);
ExitLibraryReorderCommand createExitLibraryReorderCommand(Ref ref) =>
    () => ref.read(libraryReorderModeProvider.notifier).exit();
BulkEditComicMetadataCommand createBulkEditComicMetadataCommand(Ref ref) =>
    ({required comicIds, required patch}) => ref
        .read(comicMetadataBulkPatchControllerProvider.notifier)
        .apply(comicIds: comicIds, patch: patch);
StartLibraryScanCommand createStartLibraryScanCommand(Ref ref) =>
    ({
      mode = ScanMode.incremental,
      syncAll = false,
      targetLibraryId,
      silent = false,
    }) => ref
        .read(scanLibraryControllerProvider.notifier)
        .start(
          mode: mode,
          syncAll: syncAll,
          targetLibraryId: targetLibraryId,
          silent: silent,
        );
CancelLibraryScanCommand createCancelLibraryScanCommand(Ref ref) =>
    () => ref.read(scanLibraryControllerProvider.notifier).cancel();
RefreshComicMetadataCommand createRefreshComicMetadataCommand(Ref ref) =>
    ({required comicId, required title}) => ref
        .read(metadataRefreshControllerProvider.notifier)
        .refreshComic(comicId: comicId, title: title);
RefreshSeriesMetadataCommand createRefreshSeriesMetadataCommand(Ref ref) =>
    ({required seriesId, required name}) => ref
        .read(metadataRefreshControllerProvider.notifier)
        .refreshSeries(seriesId: seriesId, name: name);
RefreshLibraryMetadataCommand createRefreshLibraryMetadataCommand(Ref ref) =>
    ({required libraryId, required name}) => ref
        .read(metadataRefreshControllerProvider.notifier)
        .refreshLibrary(libraryId: libraryId, name: name);
CancelMetadataRefreshCommand createCancelMetadataRefreshCommand(Ref ref) =>
    () => ref.read(metadataRefreshControllerProvider.notifier).cancel();
