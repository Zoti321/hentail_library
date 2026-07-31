import 'package:hentai_library/domain/library/library_comic_sort_option.dart';
import 'package:hentai_library/domain/models/entity/comic/comic.dart';
import 'package:hentai_library/domain/models/enums.dart';
import 'package:test/test.dart';

Comic _comic({
  required String id,
  required String title,
  DateTime? lastReadTime,
}) {
  final DateTime now = DateTime.utc(2026, 1, 1);
  return Comic(
    comicId: id,
    path: '/tmp/$id',
    resourceType: ResourceType.zip,
    resourceSize: 1024,
    createdAt: now,
    lastUpdatedAt: now,
    title: title,
    pageCount: 10,
    lastReadTime: lastReadTime,
  );
}

void main() {
  group('LibraryComicSortOption.compare(readAt)', () {
    test('orders by lastReadTime ascending', () {
      final Comic older = _comic(
        id: 'a',
        title: 'Zebra',
        lastReadTime: DateTime.utc(2026, 1, 1),
      );
      final Comic newer = _comic(
        id: 'b',
        title: 'Alpha',
        lastReadTime: DateTime.utc(2026, 6, 1),
      );
      final LibraryComicSortOption option = LibraryComicSortOption(
        field: LibraryComicSortField.readAt,
      );

      expect(option.compare(older, newer), lessThan(0));
      expect(option.compare(newer, older), greaterThan(0));
    });

    test('orders by lastReadTime descending', () {
      final Comic older = _comic(
        id: 'a',
        title: 'Zebra',
        lastReadTime: DateTime.utc(2026, 1, 1),
      );
      final Comic newer = _comic(
        id: 'b',
        title: 'Alpha',
        lastReadTime: DateTime.utc(2026, 6, 1),
      );
      final LibraryComicSortOption option = LibraryComicSortOption(
        field: LibraryComicSortField.readAt,
        descending: true,
      );

      expect(option.compare(newer, older), lessThan(0));
      expect(option.compare(older, newer), greaterThan(0));
    });

    test('null lastReadTime sorts after non-null in both directions', () {
      final Comic read = _comic(
        id: 'a',
        title: 'Zebra',
        lastReadTime: DateTime.utc(2026, 1, 1),
      );
      final Comic unread = _comic(id: 'b', title: 'Alpha');

      final LibraryComicSortOption ascending = LibraryComicSortOption(
        field: LibraryComicSortField.readAt,
      );
      final LibraryComicSortOption descending = LibraryComicSortOption(
        field: LibraryComicSortField.readAt,
        descending: true,
      );

      expect(ascending.compare(read, unread), lessThan(0));
      expect(ascending.compare(unread, read), greaterThan(0));
      expect(descending.compare(read, unread), lessThan(0));
      expect(descending.compare(unread, read), greaterThan(0));
    });
  });
}
