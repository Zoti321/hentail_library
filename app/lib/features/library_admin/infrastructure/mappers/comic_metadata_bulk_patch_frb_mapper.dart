import 'package:hentai_library/features/library_admin/domain/comic_metadata_bulk_patch.dart';
import 'package:hentai_library/src/rust/api/comic.dart' as comic_rust;

comic_rust.ComicMetadataBulkPatchFrbDto mapComicMetadataBulkPatchToFrb(
  ComicMetadataBulkPatch patch,
) {
  return comic_rust.ComicMetadataBulkPatchFrbDto(
    tags: patch.tags == null ? null : _mapMultiValue(patch.tags!),
    authors: patch.authors == null ? null : _mapMultiValue(patch.authors!),
    languages: patch.languages == null
        ? null
        : _mapMultiValue(patch.languages!),
    parodies: patch.parodies == null ? null : _mapMultiValue(patch.parodies!),
    characters: patch.characters == null
        ? null
        : _mapMultiValue(patch.characters!),
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
      ComicMetadataBulkMultiValueOp.add => comic_rust.MultiValueOpFrbDto.add,
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
) => switch (patch) {
  ComicMetadataBulkPublishedAtReplace(:final value) =>
    comic_rust.PublishedAtPatchFrbDto.replace(value.millisecondsSinceEpoch),
  ComicMetadataBulkPublishedAtClear() =>
    comic_rust.PublishedAtPatchFrbDto.clear(),
};
