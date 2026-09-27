import 'package:hentai_library/data/adapters/frb_call_guard.dart';
import 'package:hentai_library/data/adapters/remote_credentials_frb.dart';
import 'package:hentai_library/domain/library/comic_metadata_bulk_patch_types.dart';
import 'package:hentai_library/domain/repositories/library_repository.dart';
import 'package:hentai_library/src/rust/api/comic.dart' as comic_rust;
import 'package:hentai_library/src/rust/api/sync.dart' as sync_rust;

class ComicMetadataBulkPatchFrbAdapter {
  ComicMetadataBulkPatchFrbAdapter({required LibraryRepository libraryRepository})
    : _libraryRepository = libraryRepository;

  final LibraryRepository _libraryRepository;
  sync_rust.SyncHandleDto? _activeHandle;

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
          patch: _mapPatch(patch),
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

  void cancelActive() {
    final sync_rust.SyncHandleDto? handle = _activeHandle;
    if (handle != null) {
      sync_rust.cancelSyncFrb(handle: handle);
    }
  }

  comic_rust.ComicMetadataBulkPatchFrbDto _mapPatch(
    ComicMetadataBulkPatch patch,
  ) {
    return comic_rust.ComicMetadataBulkPatchFrbDto(
      tags: patch.tags == null ? null : _mapMultiValue(patch.tags!),
      authors: patch.authors == null ? null : _mapMultiValue(patch.authors!),
      languages: patch.languages == null ? null : _mapMultiValue(patch.languages!),
      parodies: patch.parodies == null ? null : _mapMultiValue(patch.parodies!),
      characters: patch.characters == null ? null : _mapMultiValue(patch.characters!),
      contentRating: patch.contentRating,
      description: patch.description == null
          ? null
          : _mapDescription(patch.description!),
      publishedAt: patch.publishedAt == null
          ? null
          : _mapPublishedAt(patch.publishedAt!),
    );
  }

  comic_rust.MultiValuePatchFrbDto _mapMultiValue(
    ComicMetadataBulkMultiValuePatch patch,
  ) {
    return comic_rust.MultiValuePatchFrbDto(
      op: switch (patch.op) {
        ComicMetadataBulkMultiValueOp.add =>
          comic_rust.MultiValueOpFrbDto.add,
        ComicMetadataBulkMultiValueOp.remove =>
          comic_rust.MultiValueOpFrbDto.remove,
        ComicMetadataBulkMultiValueOp.replace =>
          comic_rust.MultiValueOpFrbDto.replace,
      },
      values: patch.values,
    );
  }

  comic_rust.ScalarPatchFrbDto _mapDescription(
    ComicMetadataBulkDescriptionPatch patch,
  ) {
    return switch (patch.op) {
      ComicMetadataBulkScalarOp.replace => comic_rust.ScalarPatchFrbDto.replace(
        patch.value ?? '',
      ),
      ComicMetadataBulkScalarOp.clear => comic_rust.ScalarPatchFrbDto.clear(),
    };
  }

  comic_rust.PublishedAtPatchFrbDto _mapPublishedAt(
    ComicMetadataBulkPublishedAtPatch patch,
  ) {
    return switch (patch.op) {
      ComicMetadataBulkScalarOp.replace =>
        comic_rust.PublishedAtPatchFrbDto.replace(patch.value ?? 0),
      ComicMetadataBulkScalarOp.clear =>
        comic_rust.PublishedAtPatchFrbDto.clear(),
    };
  }
}
