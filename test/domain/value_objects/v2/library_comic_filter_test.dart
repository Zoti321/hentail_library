import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/data/services/comic/v2/resource_types.dart';
import 'package:hentai_library/domain/entity/v2/content_rating.dart';
import 'package:hentai_library/domain/entity/v2/library_comic.dart';
import 'package:hentai_library/domain/entity/v2/library_tag.dart';
import 'package:hentai_library/domain/value_objects/v2/library_comic_filter.dart';
import 'package:hentai_library/domain/value_objects/v2/library_tag_pick.dart';

void main() {
  LibraryComic comic({
    required ResourceType type,
    required ContentRating rating,
    required List<LibraryTag> tags,
  }) {
    return LibraryComic(
      comicId: 'c1',
      path: '/x',
      resourceType: type,
      title: 'T',
      authors: const [],
      contentRating: rating,
      tags: tags,
    );
  }

  group('LibraryComicFilter.matches', () {
    test('filters by resourceTypes', () {
      final c = comic(
        type: ResourceType.zip,
        rating: ContentRating.unknown,
        tags: const [],
      );
      expect(
        LibraryComicFilter(resourceTypes: {ResourceType.zip}).matches(c),
        isTrue,
      );
      expect(
        LibraryComicFilter(resourceTypes: {ResourceType.dir}).matches(c),
        isFalse,
      );
    });

    test('filters by contentRatings', () {
      final c = comic(
        type: ResourceType.dir,
        rating: ContentRating.safe,
        tags: const [],
      );
      expect(
        LibraryComicFilter(contentRatings: {ContentRating.safe}).matches(c),
        isTrue,
      );
      expect(
        LibraryComicFilter(contentRatings: {ContentRating.r18}).matches(c),
        isFalse,
      );
    });

    test('filters by tagsAll (AND)', () {
      final t1 = LibraryTag(name: 'a');
      final t2 = LibraryTag(name: 'b');
      final c = comic(
        type: ResourceType.dir,
        rating: ContentRating.unknown,
        tags: [t1, t2],
      );
      final p1 = LibraryTagPick(name: 'a');
      final p2 = LibraryTagPick(name: 'b');
      expect(LibraryComicFilter(tagsAll: {p1}).matches(c), isTrue);
      expect(LibraryComicFilter(tagsAll: {p1, p2}).matches(c), isTrue);
      expect(
        LibraryComicFilter(
          tagsAll: {
            p1,
            LibraryTagPick(name: 'c'),
          },
        ).matches(c),
        isFalse,
      );
    });

    test('filters by tagsAny (OR)', () {
      final t1 = LibraryTag(name: 'a');
      final c = comic(
        type: ResourceType.dir,
        rating: ContentRating.unknown,
        tags: [t1],
      );
      final p1 = LibraryTagPick(name: 'a');
      final p2 = LibraryTagPick(name: 'b');
      expect(LibraryComicFilter(tagsAny: {p1, p2}).matches(c), isTrue);
      expect(LibraryComicFilter(tagsAny: {p2}).matches(c), isFalse);
    });

    test('filters by tagsExclude (NOT)', () {
      final t1 = LibraryTag(name: 'a');
      final c = comic(
        type: ResourceType.dir,
        rating: ContentRating.unknown,
        tags: [t1],
      );
      final pa = LibraryTagPick(name: 'a');
      expect(
        LibraryComicFilter(
          tagsExclude: {
            LibraryTagPick(name: 'b'),
          },
        ).matches(c),
        isTrue,
      );
      expect(LibraryComicFilter(tagsExclude: {pa}).matches(c), isFalse);
    });

    test('combines filters (resourceType + rating + tags)', () {
      final t = LibraryTag(name: 'x');
      final c = comic(
        type: ResourceType.epub,
        rating: ContentRating.safe,
        tags: [t],
      );
      final f = LibraryComicFilter(
        resourceTypes: {ResourceType.epub},
        contentRatings: {ContentRating.safe},
        tagsAll: {
          LibraryTagPick(name: 'x'),
        },
      );
      expect(f.matches(c), isTrue);
    });
  });
}

