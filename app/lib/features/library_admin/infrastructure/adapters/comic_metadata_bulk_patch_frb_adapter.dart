import 'package:hentai_library/infrastructure/frb/frb_call_guard.dart';
import 'package:hentai_library/features/library_admin/infrastructure/adapters/remote_credentials_frb_adapter.dart';
import 'package:hentai_library/features/library_admin/infrastructure/mappers/comic_metadata_bulk_patch_frb_mapper.dart';
import 'package:hentai_library/features/library_admin/domain/comic_metadata_bulk_patch_port.dart';
import 'package:hentai_library/features/library_admin/domain/comic_metadata_bulk_patch.dart';
import 'package:hentai_library/features/library_admin/domain/library_repository.dart';
import 'package:hentai_library/src/rust/api/comic.dart' as comic_rust;
import 'package:hentai_library/src/rust/api/sync.dart' as sync_rust;

class ComicMetadataBulkPatchFrbAdapter implements ComicMetadataBulkPatchPort {
  ComicMetadataBulkPatchFrbAdapter({required this._libraryRepository});

  final LibraryRepository _libraryRepository;
  sync_rust.SyncHandleDto? _activeHandle;

  @override
  Future<ComicMetadataBulkPatchResult> apply({
    required List<String> comicIds,
    required ComicMetadataBulkPatch patch,
  }) async {
    await pushRemoteLibraryCredentials(_libraryRepository);
    final sync_rust.SyncHandleDto handle = sync_rust.createSyncHandleFrb();
    _activeHandle = handle;
    try {
      final comic_rust.BulkPatchResultFrbDto result = await guardFrb(
        () => comic_rust.applyComicMetadataBulkPatchFrb(
          comicIds: comicIds,
          patch: mapComicMetadataBulkPatchToFrb(patch),
          handle: handle,
        ),
        fallbackMessage: '批量编辑元数据失败',
      );
      return (
        succeeded: result.succeeded,
        failed: result.failed,
        unchanged: result.unchanged,
        cancelled: result.cancelled,
        errorSamples: result.errorSamples,
      );
    } finally {
      _activeHandle = null;
    }
  }

  @override
  void cancelActive() {
    final sync_rust.SyncHandleDto? handle = _activeHandle;
    if (handle != null) {
      sync_rust.cancelSyncFrb(handle: handle);
    }
  }
}
