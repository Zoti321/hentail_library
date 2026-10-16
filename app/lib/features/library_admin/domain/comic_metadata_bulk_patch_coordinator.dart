import 'package:hentai_library/domain/library/comic_metadata_bulk_patch_port.dart';
import 'package:hentai_library/domain/library/comic_metadata_bulk_patch_types.dart';

/// UI-side helper: FRB bulk patch + catalog revision bump.
class ComicMetadataBulkPatchCoordinator {
  const ComicMetadataBulkPatchCoordinator({
    required ComicMetadataBulkPatchPort adapter,
    required void Function() onSucceeded,
    required void Function({
      required bool tagsWritten,
      required bool authorsWritten,
      required bool parodiesWritten,
      required bool charactersWritten,
    })
    onDictionariesChanged,
  }) : _adapter = adapter,
       _onSucceeded = onSucceeded,
       _onDictionariesChanged = onDictionariesChanged;

  final ComicMetadataBulkPatchPort _adapter;
  final void Function() _onSucceeded;
  final void Function({
    required bool tagsWritten,
    required bool authorsWritten,
    required bool parodiesWritten,
    required bool charactersWritten,
  })
  _onDictionariesChanged;

  Future<ComicMetadataBulkPatchResult> apply({
    required List<String> comicIds,
    required ComicMetadataBulkPatch patch,
  }) async {
    final ComicMetadataBulkPatchResult result = await _adapter.apply(
      comicIds: comicIds,
      patch: patch,
    );
    if (result.succeeded > 0) {
      _onSucceeded();
      _onDictionariesChanged(
        tagsWritten: patch.tags != null,
        authorsWritten: patch.authors != null,
        parodiesWritten: patch.parodies != null,
        charactersWritten: patch.characters != null,
      );
    }
    return result;
  }

  void cancelActive() => _adapter.cancelActive();
}
