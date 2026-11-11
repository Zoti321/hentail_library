import 'package:hentai_library/features/library_admin/presentation/view_models/comic_metadata_bulk_patch_controller.dart';
import 'package:hentai_library/features/library_admin/presentation/view_models/metadata_refresh_controller.dart';
import 'package:hentai_library/features/library_admin/presentation/view_models/scan_library_controller.dart';
import 'package:hentai_library/features/library_admin/domain/library_metadata_refresh_command_port.dart';
import 'package:hentai_library/features/library_admin/domain/metadata_refresh_types.dart';
import 'package:hentai_library/features/library_admin/domain/library_scan_command_port.dart';
import 'package:hentai_library/features/library_admin/domain/library_sidebar_layout.dart';
import 'package:hentai_library/features/library_admin/domain/sync_library_types.dart';
import 'package:hentai_library/features/library_admin/presentation/view_models/libraries_notifier.dart';
import 'package:hentai_library/features/library_admin/presentation/view_models/library_reorder_mode_notifier.dart';
import 'package:hentai_library/features/library_admin/domain/comic_metadata_bulk_edit_command_port.dart';
import 'package:hentai_library/shared/domain/library/comic_metadata_bulk_patch.dart';
import 'package:hentai_library/features/library_admin/domain/libraries_port.dart';
import 'package:hentai_library/features/library_admin/domain/library_reorder_mode_port.dart';
import 'package:hentai_library/shared/domain/models/entity/library/local_library.dart';
import 'package:hentai_library/features/library_admin/domain/value_objects/library_form.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class _LibrariesAdapter implements LibrariesPort {
  _LibrariesAdapter(this._ref);

  final Ref _ref;

  @override
  Future<void> deleteLibrary(String libraryId) =>
      _ref.read(librariesProvider.notifier).deleteLibrary(libraryId);

  @override
  Future<void> updateSidebarLayout(List<LibrarySidebarPlacement> placements) =>
      _ref.read(librariesProvider.notifier).updateSidebarLayout(placements);

  @override
  Future<LibraryFormApplyResult> submitLibraryForm(
    LibraryForm form, {
    LocalLibrary? original,
  }) => _ref
      .read(librariesProvider.notifier)
      .submitLibraryForm(form, original: original);
}

class _ComicMetadataBulkEditCommandAdapter
    implements ComicMetadataBulkEditCommandPort {
  _ComicMetadataBulkEditCommandAdapter(this._ref);

  final Ref _ref;

  @override
  Future<ComicMetadataBulkPatchResult> apply({
    required List<String> comicIds,
    required ComicMetadataBulkPatch patch,
  }) => _ref
      .read(comicMetadataBulkPatchControllerProvider.notifier)
      .apply(comicIds: comicIds, patch: patch);
}

class _LibraryScanCommandAdapter implements LibraryScanCommandPort {
  _LibraryScanCommandAdapter(this._ref);

  final Ref _ref;

  @override
  Future<void> start({
    ScanMode mode = ScanMode.incremental,
    bool syncAll = false,
    String? targetLibraryId,
    bool silent = false,
  }) => _ref
      .read(scanLibraryControllerProvider.notifier)
      .start(
        mode: mode,
        syncAll: syncAll,
        targetLibraryId: targetLibraryId,
        silent: silent,
      );

  @override
  void cancel() => _ref.read(scanLibraryControllerProvider.notifier).cancel();
}

class _LibraryMetadataRefreshCommandAdapter
    implements LibraryMetadataRefreshCommandPort {
  _LibraryMetadataRefreshCommandAdapter(this._ref);

  final Ref _ref;

  MetadataRefreshController get _controller =>
      _ref.read(metadataRefreshControllerProvider.notifier);

  @override
  Future<void> refreshComic({required String comicId, required String title}) =>
      _controller.refreshComic(comicId: comicId, title: title);

  @override
  Future<MetadataRefreshBatchResult> refreshSeries({
    required String seriesId,
    required String name,
  }) => _controller.refreshSeries(seriesId: seriesId, name: name);

  @override
  Future<MetadataRefreshBatchResult> refreshLibrary({
    required String libraryId,
    required String name,
  }) => _controller.refreshLibrary(libraryId: libraryId, name: name);

  @override
  void cancel() => _controller.cancel();

  @override
  bool isRefreshingSeries(String seriesId) =>
      _controller.isRefreshingSeries(seriesId);

  @override
  bool get running => _ref.read(metadataRefreshControllerProvider).running;
}

class _LibraryReorderModeAdapter implements LibraryReorderModePort {
  _LibraryReorderModeAdapter(this._ref);

  final Ref _ref;

  @override
  bool get isActive => _ref.read(libraryReorderModeProvider);

  @override
  void enter() => _ref.read(libraryReorderModeProvider.notifier).enter();

  @override
  void exit() => _ref.read(libraryReorderModeProvider.notifier).exit();
}

LibrariesPort createLibrariesPort(Ref ref) => _LibrariesAdapter(ref);

LibraryReorderModePort createLibraryReorderModePort(Ref ref) =>
    _LibraryReorderModeAdapter(ref);

ComicMetadataBulkEditCommandPort createComicMetadataBulkEditCommandPort(
  Ref ref,
) => _ComicMetadataBulkEditCommandAdapter(ref);

LibraryScanCommandPort createLibraryScanCommandPort(Ref ref) =>
    _LibraryScanCommandAdapter(ref);

LibraryMetadataRefreshCommandPort createLibraryMetadataRefreshCommandPort(
  Ref ref,
) => _LibraryMetadataRefreshCommandAdapter(ref);
