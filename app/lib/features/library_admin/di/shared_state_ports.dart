import 'package:hentai_library/features/library_admin/presentation/view_models/comic_metadata_bulk_patch_controller.dart';
import 'package:hentai_library/features/library_admin/presentation/view_models/scan_library_controller.dart';
import 'package:hentai_library/shared/domain/library/library_scan_command_port.dart';
import 'package:hentai_library/shared/domain/library/sync_library_types.dart';
import 'package:hentai_library/features/library_admin/presentation/view_models/current_library_notifier.dart';
import 'package:hentai_library/features/library_admin/presentation/view_models/library_reorder_mode_notifier.dart';
import 'package:hentai_library/features/library_admin/presentation/view_models/library_revision_notifier.dart';
import 'package:hentai_library/shared/domain/library/comic_metadata_bulk_edit_command_port.dart';
import 'package:hentai_library/shared/domain/library/comic_metadata_bulk_patch_types.dart';
import 'package:hentai_library/shared/domain/library/current_library_port.dart';
import 'package:hentai_library/shared/domain/library/library_reorder_mode_port.dart';
import 'package:hentai_library/shared/domain/models/entity/library/local_library.dart';
import 'package:hentai_library/shared/domain/models/value_objects/form/library_form.dart';
import 'package:hentai_library/shared/domain/ports/library_revision_signal_port.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// library_admin 对共享状态端口的实现（#260 步骤0）。
///
/// 仅委托到现有 Notifier，不改变其行为；消费方在后续 slice 中改为依赖端口。
class _CurrentLibraryAdapter implements CurrentLibraryPort {
  _CurrentLibraryAdapter(this._ref);

  final Ref _ref;

  @override
  Future<String?> currentId() async {
    final CurrentLibraryState state = await _ref.read(
      currentLibraryProvider.future,
    );
    return state.currentId;
  }

  @override
  Future<void> select(String libraryId) =>
      _ref.read(currentLibraryProvider.notifier).select(libraryId);

  @override
  Future<void> clear() => _ref.read(currentLibraryProvider.notifier).clear();

  @override
  Future<void> deleteLibrary(String libraryId) =>
      _ref.read(currentLibraryProvider.notifier).deleteLibrary(libraryId);

  @override
  Future<LibraryFormApplyResult> submitLibraryForm(
    LibraryForm form, {
    LocalLibrary? original,
  }) => _ref
      .read(currentLibraryProvider.notifier)
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
    bool silent = false,
  }) => _ref
      .read(scanLibraryControllerProvider.notifier)
      .start(mode: mode, syncAll: syncAll, silent: silent);
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

class _LibraryRevisionSignalAdapter implements LibraryRevisionSignalPort {
  _LibraryRevisionSignalAdapter(this._ref);

  final Ref _ref;

  @override
  void notifyExternalChange() =>
      _ref.read(libraryRevisionProvider.notifier).notifyExternalChange();
}

/// 适配器工厂：由 bootstrap 通过 `shared/di` 的端口 Provider `overrideWith` 注入（#261a）。
CurrentLibraryPort createCurrentLibraryPort(Ref ref) =>
    _CurrentLibraryAdapter(ref);

LibraryReorderModePort createLibraryReorderModePort(Ref ref) =>
    _LibraryReorderModeAdapter(ref);

LibraryRevisionSignalPort createLibraryRevisionSignalPort(Ref ref) =>
    _LibraryRevisionSignalAdapter(ref);

ComicMetadataBulkEditCommandPort createComicMetadataBulkEditCommandPort(
  Ref ref,
) => _ComicMetadataBulkEditCommandAdapter(ref);

LibraryScanCommandPort createLibraryScanCommandPort(Ref ref) =>
    _LibraryScanCommandAdapter(ref);
