import 'package:hentai_library/features/library_admin/domain/comic_metadata_bulk_patch.dart';
import 'package:hentai_library/features/library_admin/infrastructure/mappers/comic_metadata_bulk_patch_frb_mapper.dart';
import 'package:hentai_library/src/rust/api/comic.dart' as rust;
import 'package:test/test.dart';

void main() {
  test('an omitted patch keeps every FRB field omitted', () {
    expect(
      mapComicMetadataBulkPatchToFrb(const ComicMetadataBulkPatch()),
      const rust.ComicMetadataBulkPatchFrbDto(),
    );
  });

  for (final date in [
    DateTime.utc(2026, 11, 13, 12, 30, 45, 123, 456),
    DateTime(2026, 11, 13, 12, 30, 45, 123, 456),
    DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
    DateTime.fromMillisecondsSinceEpoch(-1, isUtc: true),
  ]) {
    test('replacement encodes the exact epoch milliseconds of $date', () {
      final mapped = mapComicMetadataBulkPatchToFrb(
        ComicMetadataBulkPatch(
          publishedAt: ComicMetadataBulkPublishedAtPatch.replace(date),
        ),
      );
      expect(
        mapped.publishedAt,
        rust.PublishedAtPatchFrbDto.replace(date.millisecondsSinceEpoch),
      );
      expect(mapped.description, isNull);
    });
  }

  test('clear encodes the dedicated FRB variant rather than epoch zero', () {
    final mapped = mapComicMetadataBulkPatchToFrb(
      const ComicMetadataBulkPatch(
        publishedAt: ComicMetadataBulkPublishedAtPatch.clear(),
      ),
    );
    expect(mapped.publishedAt, const rust.PublishedAtPatchFrbDto.clear());
    expect(
      mapped.publishedAt,
      isNot(const rust.PublishedAtPatchFrbDto.replace(0)),
    );
  });

  for (final (operation, expected) in [
    (ComicMetadataBulkMultiValueOp.add, rust.MultiValueOpFrbDto.add),
    (ComicMetadataBulkMultiValueOp.remove, rust.MultiValueOpFrbDto.remove),
    (ComicMetadataBulkMultiValueOp.replace, rust.MultiValueOpFrbDto.replace),
  ]) {
    test('all multi-value fields preserve values and operation $operation', () {
      final values = <String, List<String>>{
        'tags': [' tag ', 'tag'],
        'authors': ['Author'],
        'languages': ['ja', 'en'],
        'parodies': ['Parody'],
        'characters': ['Character'],
      };
      ComicMetadataBulkMultiValuePatch field(String name) =>
          ComicMetadataBulkMultiValuePatch(
            op: operation,
            values: values[name]!,
          );
      final mapped = mapComicMetadataBulkPatchToFrb(
        ComicMetadataBulkPatch(
          tags: field('tags'),
          authors: field('authors'),
          languages: field('languages'),
          parodies: field('parodies'),
          characters: field('characters'),
          contentRating: 'r18',
          description: const ComicMetadataBulkDescriptionPatch.replace(
            '  Description  ',
          ),
        ),
      );
      final mappedFields = {
        'tags': mapped.tags,
        'authors': mapped.authors,
        'languages': mapped.languages,
        'parodies': mapped.parodies,
        'characters': mapped.characters,
      };
      for (final entry in mappedFields.entries) {
        expect(entry.value!.op, expected, reason: entry.key);
        expect(entry.value!.values, same(values[entry.key]), reason: entry.key);
      }
      expect(mapped.contentRating, 'r18');
      expect(
        mapped.description,
        const rust.ScalarPatchFrbDto.replace('  Description  '),
      );
      expect(mapped.publishedAt, isNull);
    });
  }

  test('description clear keeps its existing FRB operation', () {
    final mapped = mapComicMetadataBulkPatchToFrb(
      const ComicMetadataBulkPatch(
        description: ComicMetadataBulkDescriptionPatch.clear(),
      ),
    );
    expect(mapped.description, const rust.ScalarPatchFrbDto.clear());
    expect(mapped.publishedAt, isNull);
  });

  test(
    'a null description replacement keeps the existing empty-string fallback',
    () {
      final mapped = mapComicMetadataBulkPatchToFrb(
        const ComicMetadataBulkPatch(
          description: ComicMetadataBulkDescriptionPatch.replace(null),
        ),
      );
      expect(mapped.description, const rust.ScalarPatchFrbDto.replace(''));
      expect(mapped.publishedAt, isNull);
    },
  );
}
