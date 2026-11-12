import 'package:hentai_library/features/library_admin/domain/comic_metadata_bulk_patch.dart';

typedef BulkEditComicMetadataCommand =
    Future<ComicMetadataBulkPatchResult> Function({
      required List<String> comicIds,
      required ComicMetadataBulkPatch patch,
    });
