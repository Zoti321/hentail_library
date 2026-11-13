import 'package:hentai_library/features/library_admin/domain/comic_metadata_bulk_patch.dart';
import 'package:test/test.dart';

void main() {
  for (final date in [
    DateTime.utc(2026, 11, 13, 12, 30, 45, 123),
    DateTime(2026, 11, 13, 12, 30, 45, 123),
    DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
  ]) {
    test('replace retains the supplied DateTime $date', () {
      final patch = ComicMetadataBulkPublishedAtPatch.replace(date);
      expect(
        patch,
        isA<ComicMetadataBulkPublishedAtReplace>().having(
          (replace) => replace.value,
          'value',
          same(date),
        ),
      );
      expect(patch, isNot(isA<ComicMetadataBulkPublishedAtClear>()));
    });
  }

  test('clear is a separate variant from a legitimate epoch replacement', () {
    const clear = ComicMetadataBulkPublishedAtPatch.clear();
    final replace = ComicMetadataBulkPublishedAtPatch.replace(
      DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
    );
    expect(clear, isA<ComicMetadataBulkPublishedAtClear>());
    expect(clear, isNot(isA<ComicMetadataBulkPublishedAtReplace>()));
    expect(
      replace,
      isA<ComicMetadataBulkPublishedAtReplace>().having(
        (value) => value.value.millisecondsSinceEpoch,
        'epoch',
        0,
      ),
    );
  });

  test('omitted dates are distinct from an enabled clear field', () {
    const omitted = ComicMetadataBulkPatch();
    const clear = ComicMetadataBulkPatch(
      publishedAt: ComicMetadataBulkPublishedAtPatch.clear(),
    );
    expect(omitted.publishedAt, isNull);
    expect(omitted.enabledFieldCount, 0);
    expect(clear.publishedAt, isA<ComicMetadataBulkPublishedAtClear>());
    expect(clear.enabledFieldCount, 1);
  });
}
