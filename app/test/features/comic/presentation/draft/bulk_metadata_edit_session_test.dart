import 'package:hentai_library/features/comic/public/comic_metadata_types.dart';
import 'package:hentai_library/features/comic/presentation/draft/bulk_metadata_edit_session.dart';
import 'package:hentai_library/features/comic/domain/comic.dart';
import 'package:hentai_library/features/comic_metadata/public/comic_metadata_entities.dart';
import 'package:hentai_library/shared/domain/models/enums.dart';
import 'package:test/test.dart';
import 'package:hentai_library/features/library_admin/public.dart';

Comic _comic({
  required String id,
  List<String> tags = const <String>['t1'],
  String description = 'd',
}) {
  return Comic.restore(
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
  for (final text in ['', '   ', 'not a date']) {
    test(
      'dirty replacement with "$text" cannot build even another field patch',
      () {
        final session = BulkMetadataEditSession();
        session.publishedAtField.publishedAtText = text;
        session.markDirty(BulkMetadataEditFieldKind.publishedAt);
        session.markDirty(BulkMetadataEditFieldKind.tags);
        expect(session.hasInvalidPublishedAt, isTrue);
        expect(session.buildPatch(), isNull);
        expect(session.publishedAtField.publishedAtText, text);
      },
    );
  }

  test('untouched invalid date text does not block other field changes', () {
    final session = BulkMetadataEditSession();
    session.publishedAtField.publishedAtText = 'not a date';
    session.markDirty(BulkMetadataEditFieldKind.tags);
    expect(session.hasInvalidPublishedAt, isFalse);
    expect(session.buildPatch()!.publishedAt, isNull);
  });

  test('explicit clear needs no date and leaves other fields sparse', () {
    final session = BulkMetadataEditSession();
    session.publishedAtField.op = ComicMetadataBulkScalarOp.clear;
    session.markDirty(BulkMetadataEditFieldKind.publishedAt);
    expect(session.hasInvalidPublishedAt, isFalse);
    final patch = session.buildPatch()!;
    expect(patch.publishedAt, isA<ComicMetadataBulkPublishedAtClear>());
    expect(patch.tags, isNull);
    expect(patch.enabledFieldCount, 1);
    session.publishedAtField.op = ComicMetadataBulkScalarOp.replace;
    expect(session.hasInvalidPublishedAt, isTrue);
    expect(session.buildPatch(), isNull);
  });

  for (final date in [
    DateTime.utc(2026, 1, 2),
    DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
  ]) {
    test(
      'valid replacement retains DateTime $date including the real epoch',
      () {
        final session = BulkMetadataEditSession();
        session.publishedAtField.publishedAtText =
            '  ${date.toIso8601String()}  ';
        session.markDirty(BulkMetadataEditFieldKind.publishedAt);
        expect(session.hasInvalidPublishedAt, isFalse);
        final patch =
            session.buildPatch()!.publishedAt
                as ComicMetadataBulkPublishedAtReplace;
        expect(patch.value, date);
      },
    );
  }

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
