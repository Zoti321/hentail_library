import 'package:hentai_library/features/comic/public/comic_metadata_types.dart';
import 'package:hentai_library/features/comic/domain/comic.dart';
import 'package:hentai_library/features/comic/domain/value_objects/comic_metadata_form.dart';
import 'package:hentai_library/features/comic_metadata/public/comic_metadata_entities.dart';
import 'package:hentai_library/shared/domain/models/enums.dart';
import 'package:hentai_library/shared/domain/models/value_objects/author_ref.dart';
import 'package:test/test.dart';

Comic _comic({
  String title = '原标题',
  String? description,
  DateTime? publishedAt,
  ContentRating contentRating = ContentRating.safe,
  List<AuthorRef> authors = const <AuthorRef>[],
  List<Tag> tags = const <Tag>[],
  List<String> languages = const <String>[],
  List<String> parodies = const <String>[],
  List<String> characters = const <String>[],
}) {
  final DateTime now = DateTime.utc(2024, 1, 1);
  return Comic.restore(
    comicId: 'comic-1',
    path: '/library/comic-1',
    resourceType: ResourceType.dir,
    resourceSize: 0,
    createdAt: now,
    lastUpdatedAt: now,
    title: title,
    description: description,
    publishedAt: publishedAt,
    contentRating: contentRating,
    authors: authors,
    tags: tags,
    languages: languages,
    parodies: parodies,
    characters: characters,
    pageCount: 1,
  );
}

ComicMetadataDraftChanges _changedFields(ComicMetadataDraftDiff diff) {
  expect(diff, isA<ComicMetadataDraftChanges>());
  return diff as ComicMetadataDraftChanges;
}

void main() {
  group('Comic.createMetadata', () {
    test('rejects blank title', () {
      expect(
        () => Comic.createMetadata(
          comicId: 'comic-1',
          path: '/library/comic-1',
          resourceType: ResourceType.dir,
          resourceSize: 0,
          createdAt: DateTime.utc(2024, 1, 1),
          lastUpdatedAt: DateTime.utc(2024, 1, 1),
          title: '   ',
          pageCount: 1,
        ),
        throwsArgumentError,
      );
    });

    test('trims title and normalizes facet names', () {
      final Comic comic = Comic.createMetadata(
        comicId: 'comic-1',
        path: '/library/comic-1',
        resourceType: ResourceType.dir,
        resourceSize: 0,
        createdAt: DateTime.utc(2024, 1, 1),
        lastUpdatedAt: DateTime.utc(2024, 1, 1),
        title: ' 标题 ',
        description: '  ',
        pageCount: 1,
        languages: <String>[' Chinese ', 'Japanese', 'Chinese', ''],
        parodies: <String>[' Fate ', 'Fate'],
        characters: <String>[' Saber '],
      );

      expect(comic.title, '标题');
      expect(comic.description, isNull);
      expect(comic.languages, <String>['Chinese', 'Japanese']);
      expect(comic.parodies, <String>['Fate']);
      expect(comic.characters, <String>['Saber']);
    });
  });

  group('Comic.restore', () {
    test('keeps FRB facts without business validation', () {
      expect(_comic(title: '  ').title, '  ');
    });
  });

  group('Comic.applyMetadataDraft', () {
    test('applies normalized draft onto the entity', () {
      final Comic original = _comic();
      final Comic applied = original.applyMetadataDraft(
        ComicMetadataForm(
          title: ' 新标题 ',
          description: ' 概要 ',
          publishedAt: DateTime.utc(2020, 5, 1),
          isR18: true,
          authors: <AuthorRef>[AuthorRef.byName('A')],
          tags: <Tag>[Tag(name: 'T')],
          languages: <String>['Chinese'],
          parodies: <String>['Fate'],
          characters: <String>['Saber'],
        ),
      );

      expect(applied.comicId, original.comicId);
      expect(applied.title, '新标题');
      expect(applied.description, '概要');
      expect(applied.publishedAt, DateTime.utc(2020, 5, 1));
      expect(applied.contentRating, ContentRating.r18);
      expect(applied.authors, <AuthorRef>[AuthorRef.byName('A')]);
      expect(applied.tags, <Tag>[Tag(name: 'T')]);
      expect(applied.languages, <String>['Chinese']);
      expect(applied.parodies, <String>['Fate']);
      expect(applied.characters, <String>['Saber']);
    });

    test('clears the published date when the draft has none', () {
      final Comic applied = _comic(publishedAt: DateTime.utc(2020, 5, 1))
          .applyMetadataDraft(ComicMetadataForm(title: '原标题'));

      expect(applied.publishedAt, isNull);
    });

    test('rejects a blank title', () {
      expect(
        () => _comic().applyMetadataDraft(ComicMetadataForm(title: '  ')),
        throwsArgumentError,
      );
    });
  });

  group('Comic.metadataDiffAgainst', () {
    test('blank title is invalid', () {
      final ComicMetadataDraftDiff diff = _comic().metadataDiffAgainst(
        ComicMetadataForm(title: '  '),
      );

      expect(diff, isA<ComicMetadataDraftInvalid>());
      expect(
        (diff as ComicMetadataDraftInvalid).validation.titleError,
        '漫画标题不能为空',
      );
    });

    test('submits only the changed title', () {
      final Comic original = _comic(title: '原标题', description: '简介');
      final ComicMetadataDraftChanges changes = _changedFields(
        original.metadataDiffAgainst(
          ComicMetadataForm.fromComic(original).copyWith(title: '新标题'),
        ),
      );

      expect(changes.title, '新标题');
      expect(changes.description, isNull);
      expect(changes.publishedAt, isNull);
      expect(changes.clearPublishedAt, isFalse);
      expect(changes.contentRating, isNull);
      expect(changes.authors, isNull);
      expect(changes.tags, isNull);
      expect(changes.languages, isNull);
      expect(changes.parodies, isNull);
      expect(changes.characters, isNull);
    });

    test('is unchanged when the draft matches the comic', () {
      final Comic original = _comic(description: '简介');
      expect(
        original.metadataDiffAgainst(ComicMetadataForm.fromComic(original)),
        isA<ComicMetadataDraftUnchanged>(),
      );
    });

    test('clearing the published date is a separate flag', () {
      final DateTime published = DateTime.utc(2020, 5, 1);
      final Comic original = _comic(publishedAt: published);
      final ComicMetadataDraftChanges changes = _changedFields(
        original.metadataDiffAgainst(
          ComicMetadataForm.fromComic(original).copyWith(publishedAt: null),
        ),
      );

      expect(changes.publishedAt, isNull);
      expect(changes.clearPublishedAt, isTrue);
      expect(changes.title, isNull);
    });

    test('submits authors when their order changes', () {
      final Comic original = _comic(
        authors: <AuthorRef>[AuthorRef.byName('A'), AuthorRef.byName('B')],
      );
      final ComicMetadataDraftChanges changes = _changedFields(
        original.metadataDiffAgainst(
          ComicMetadataForm.fromComic(original).copyWith(
            authors: <AuthorRef>[AuthorRef.byName('B'), AuthorRef.byName('A')],
          ),
        ),
      );

      expect(changes.authors?.map((AuthorRef a) => a.name).toList(), <String>[
        'B',
        'A',
      ]);
      expect(changes.title, isNull);
      expect(changes.tags, isNull);
    });

    test('submits languages when their order changes', () {
      final Comic original = _comic(languages: <String>['Chinese', 'Japanese']);
      final ComicMetadataDraftChanges changes = _changedFields(
        original.metadataDiffAgainst(
          ComicMetadataForm.fromComic(original)
              .copyWith(languages: <String>['Japanese', 'Chinese']),
        ),
      );

      expect(changes.languages, <String>['Japanese', 'Chinese']);
      expect(changes.title, isNull);
    });

    test('submits parodies and characters when their order changes', () {
      final Comic original = _comic(
        parodies: <String>['Fate', '原创'],
        characters: <String>['Saber', 'Rider'],
      );
      final ComicMetadataDraftChanges changes = _changedFields(
        original.metadataDiffAgainst(
          ComicMetadataForm.fromComic(original).copyWith(
            parodies: <String>['原创', 'Fate'],
            characters: <String>['Rider', 'Saber'],
          ),
        ),
      );

      expect(changes.parodies, <String>['原创', 'Fate']);
      expect(changes.characters, <String>['Rider', 'Saber']);
      expect(changes.title, isNull);
    });

    test('submits every field that differs from the comic', () {
      final DateTime published = DateTime.utc(2020, 5, 1);
      final ComicMetadataDraftChanges changes = _changedFields(
        _comic().metadataDiffAgainst(
          ComicMetadataForm(
            title: ' 新标题 ',
            description: ' 概要 ',
            publishedAt: published,
            isR18: true,
            authors: <AuthorRef>[AuthorRef.byName('A')],
            tags: <Tag>[Tag(name: 'T')],
            languages: <String>['Chinese'],
            parodies: <String>['Fate'],
            characters: <String>['Saber'],
          ),
        ),
      );

      expect(changes.title, '新标题');
      expect(changes.description, '概要');
      expect(changes.publishedAt, published);
      expect(changes.clearPublishedAt, isFalse);
      expect(changes.contentRating, ContentRating.r18);
      expect(changes.authors, <AuthorRef>[AuthorRef.byName('A')]);
      expect(changes.tags, <Tag>[Tag(name: 'T')]);
      expect(changes.languages, <String>['Chinese']);
      expect(changes.parodies, <String>['Fate']);
      expect(changes.characters, <String>['Saber']);
    });

    test('maps isR18 false back to safe content rating', () {
      final Comic original = _comic(contentRating: ContentRating.r18);
      final ComicMetadataDraftChanges changes = _changedFields(
        original.metadataDiffAgainst(
          ComicMetadataForm.fromComic(original).copyWith(isR18: false),
        ),
      );
      expect(changes.contentRating, ContentRating.safe);
    });

    test('includes a list only when that list changed', () {
      final Comic original = _comic();
      final ComicMetadataDraftChanges tagsOnly = _changedFields(
        original.metadataDiffAgainst(
          ComicMetadataForm.fromComic(original).addTag('new-tag'),
        ),
      );
      expect(tagsOnly.tags, <Tag>[Tag(name: 'new-tag')]);
      expect(tagsOnly.parodies, isNull);
      expect(tagsOnly.characters, isNull);

      final ComicMetadataDraftChanges parodyAndCharacter = _changedFields(
        original.metadataDiffAgainst(
          ComicMetadataForm.fromComic(original)
              .addParody('Fate')
              .addCharacter('Saber'),
        ),
      );
      expect(parodyAndCharacter.tags, isNull);
      expect(parodyAndCharacter.parodies, <String>['Fate']);
      expect(parodyAndCharacter.characters, <String>['Saber']);
    });
  });
}
