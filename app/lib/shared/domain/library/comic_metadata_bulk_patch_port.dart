import 'package:hentai_library/shared/domain/library/comic_metadata_bulk_patch_types.dart';

/// Domain port for bulk metadata patch (FRB implementation lives in `data/`).
abstract class ComicMetadataBulkPatchPort {
  Future<ComicMetadataBulkPatchResult> apply({
    required List<String> comicIds,
    required ComicMetadataBulkPatch patch,
  });

  void cancelActive();
}
