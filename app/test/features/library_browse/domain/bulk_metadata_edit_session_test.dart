import 'package:hentai_library/features/library_browse/domain/bulk_metadata_edit_session.dart';
import 'package:hentai_library/shared/domain/library/comic_metadata_bulk_patch_types.dart';
import 'package:hentai_library/shared/domain/models/entity/comic/comic.dart';
import 'package:hentai_library/shared/domain/models/entity/comic/tag.dart';
import 'package:hentai_library/shared/domain/models/enums.dart';
import 'package:test/test.dart';

Comic _comic({
  required String id,
  List<String> tags = const <String>['t1'],
  String description = 'd',
}) {
  return Comic(
    comicId: id,
    path: '/$id',
    resourceType: ResourceType.zip,
    resourceSize: 1,
    createdAt: DateTime.utc(2024),
    lastUpdatedAt: DateTime.utc(2024),
    title: id,
    contentRating: ContentRating.safe,
    pageCount: 1,
    description: description,
    tags: tags.map((String n) => Tag(name: n)).toList(),
    languages: const <String>['ja'],
  );
}

void main() {
  test('buildPatch returns null when no fields are dirty', () {
    final BulkMetadataEditSession session = BulkMetadataEditSession();
    expect(session.buildPatch(), isNull);
  });

  test('buildPatch includes only dirty tag field', () {
    final BulkMetadataEditSession session = BulkMetadataEditSession();
    session.markDirty(BulkMetadataEditFieldKind.tags);
    session.multiFields[BulkMetadataEditFieldKind.tags]!.values = <String>[
      'new-tag',
    ];

    final ComicMetadataBulkPatch? patch = session.buildPatch();

    expect(patch, isNotNull);
    expect(patch!.tags?.op, ComicMetadataBulkMultiValueOp.add);
    expect(patch.tags?.values, <String>['new-tag']);
    expect(patch.authors, isNull);
    expect(patch.enabledFieldCount, 1);
  });

  test('applyMixedHintsFromComics detects mixed tags', () {
    final BulkMetadataEditSession session = BulkMetadataEditSession();
    session.applyMixedHintsFromComics(<Comic>[
      _comic(id: 'a', tags: const <String>['x']),
      _comic(id: 'b', tags: const <String>['y']),
    ]);

    expect(
      session.multiFields[BulkMetadataEditFieldKind.tags]!.mixedValues,
      isTrue,
    );
    expect(
      session.multiFields[BulkMetadataEditFieldKind.languages]!.mixedValues,
      isFalse,
    );
  });
}
