import 'package:hentai_library/shared/domain/models/entity/comic/author.dart';
import 'package:hentai_library/shared/domain/models/entity/comic/comic.dart';
import 'package:hentai_library/shared/domain/models/entity/comic/tag.dart';
import 'package:hentai_library/shared/domain/models/enums.dart';
import 'package:hentai_library/shared/domain/models/value_objects/form/comic_metadata_form.dart';
import 'package:test/test.dart';

Comic _comic({
  String title = '原标题',
  String? description,
  DateTime? publishedAt,
  ContentRating contentRating = ContentRating.safe,
  List<Author> authors = const <Author>[],
  List<Tag> tags = const <Tag>[],
  List<String> languages = const <String>[],
  List<String> parodies = const <String>[],
  List<String> characters = const <String>[],
}) {
  final DateTime now = DateTime.utc(2024, 1, 1);
  return Comic(
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
  group('ComicMetadataForm.fromComic', () {
    test('maps fields and r18 content rating', () {
      final ComicMetadataForm form = ComicMetadataForm.fromComic(
        _comic(
          description: '简介',
          contentRating: ContentRating.r18,
          authors: <Author>[Author(name: 'A')],
          tags: <Tag>[Tag(name: 'T')],
        ),
      );
      expect(form.title, '原标题');
      expect(form.description, '简介');
      expect(form.isR18, isTrue);
      expect(form.authors.single.name, 'A');
      expect(form.tags.single.name, 'T');
    });

    test('non-r18 content rating maps to isR18 false', () {
      expect(
        ComicMetadataForm.fromComic(
          _comic(contentRating: ContentRating.unknown),
        ).isR18,
        isFalse,
      );
    });
  });

  group('ComicMetadataForm.validate / normalized', () {
    test('rejects blank title', () {
      final ComicMetadataFormValidation v = ComicMetadataForm(title: '  ')
          .validate();
      expect(v.isValid, isFalse);
      expect(v.titleError, '漫画标题不能为空');
    });

    test('normalized trims title and blank description', () {
      final ComicMetadataForm ready = ComicMetadataForm(
        title: ' 标题 ',
        description: '  ',
      ).normalized;
      expect(ready.title, '标题');
      expect(ready.description, isNull);
    });

    test('normalized trims and dedupes languages in order', () {
      final ComicMetadataForm ready = ComicMetadataForm(
        title: '标题',
        languages: <String>[' Chinese ', 'Japanese', 'Chinese', ''],
      ).normalized;
      expect(ready.languages, <String>['Chinese', 'Japanese']);
    });
  });

  group('ComicMetadataForm author/tag helpers', () {
    test('addAuthor trims, dedupes, and ignores blank', () {
      ComicMetadataForm form = ComicMetadataForm(title: 't');
      form = form.addAuthor('  A  ');
      form = form.addAuthor('A');
      form = form.addAuthor('  ');
      expect(form.authors, <Author>[Author(name: 'A')]);
    });

    test('removeAuthor / addTag / removeTag', () {
      ComicMetadataForm form = ComicMetadataForm(
        title: 't',
        authors: <Author>[
          Author(name: 'A'),
          Author(name: 'B'),
        ],
        tags: <Tag>[Tag(name: 'X')],
      );
      form = form.removeAuthor('A').addTag('Y').removeTag('X');
      expect(form.authors.single.name, 'B');
      expect(form.tags.single.name, 'Y');
    });
  });

  group('ComicMetadataForm.diffAgainst', () {
    test('blank title is invalid', () {
      final ComicMetadataDraftDiff diff = ComicMetadataForm(title: '  ')
          .diffAgainst(_comic());

      expect(diff, isA<ComicMetadataDraftInvalid>());
      expect(
        (diff as ComicMetadataDraftInvalid).validation.titleError,
        '漫画标题不能为空',
      );
    });

    test('submits only the changed title', () {
      final Comic original = _comic(title: '原标题', description: '简介');
      final ComicMetadataDraftChanges changes = _changedFields(
        ComicMetadataForm.fromComic(original)
            .copyWith(title: '新标题')
            .diffAgainst(original),
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
        ComicMetadataForm.fromComic(original).diffAgainst(original),
        isA<ComicMetadataDraftUnchanged>(),
      );
    });

    test('clearing the published date is a separate flag', () {
      final DateTime published = DateTime.utc(2020, 5, 1);
      final Comic original = _comic(publishedAt: published);
      final ComicMetadataDraftChanges changes = _changedFields(
        ComicMetadataForm.fromComic(original)
            .copyWith(publishedAt: null)
            .diffAgainst(original),
      );

      expect(changes.publishedAt, isNull);
      expect(changes.clearPublishedAt, isTrue);
      expect(changes.title, isNull);
    });

    test('submits authors when their order changes', () {
      final Comic original = _comic(
        authors: <Author>[
          Author(name: 'A'),
          Author(name: 'B'),
        ],
      );
      final ComicMetadataDraftChanges changes = _changedFields(
        ComicMetadataForm.fromComic(original)
            .copyWith(
              authors: <Author>[
                Author(name: 'B'),
                Author(name: 'A'),
              ],
            )
            .diffAgainst(original),
      );

      expect(changes.authors?.map((Author a) => a.name).toList(), <String>[
        'B',
        'A',
      ]);
      expect(changes.title, isNull);
      expect(changes.tags, isNull);
    });

    test('submits languages when their order changes', () {
      final Comic original = _comic(languages: <String>['Chinese', 'Japanese']);
      final ComicMetadataDraftChanges changes = _changedFields(
        ComicMetadataForm.fromComic(original)
            .copyWith(languages: <String>['Japanese', 'Chinese'])
            .diffAgainst(original),
      );

      expect(changes.languages, <String>['Japanese', 'Chinese']);
      expect(changes.title, isNull);
    });

    test('submits parodies when their order changes', () {
      final Comic original = _comic(parodies: <String>['Fate', '原创']);
      final ComicMetadataDraftChanges changes = _changedFields(
        ComicMetadataForm.fromComic(original)
            .copyWith(parodies: <String>['原创', 'Fate'])
            .diffAgainst(original),
      );

      expect(changes.parodies, <String>['原创', 'Fate']);
      expect(changes.title, isNull);
      expect(changes.languages, isNull);
    });

    test('submits characters when their order changes', () {
      final Comic original = _comic(characters: <String>['Saber', 'Rider']);
      final ComicMetadataDraftChanges changes = _changedFields(
        ComicMetadataForm.fromComic(original)
            .copyWith(characters: <String>['Rider', 'Saber'])
            .diffAgainst(original),
      );

      expect(changes.characters, <String>['Rider', 'Saber']);
      expect(changes.title, isNull);
      expect(changes.parodies, isNull);
    });

    test('submits every field that differs from the original comic', () {
      final DateTime published = DateTime.utc(2020, 5, 1);
      final Comic original = _comic();
      final ComicMetadataDraftChanges changes = _changedFields(
        ComicMetadataForm(
          title: ' 新标题 ',
          description: ' 概要 ',
          publishedAt: published,
          isR18: true,
          authors: <Author>[Author(name: 'A')],
          tags: <Tag>[Tag(name: 'T')],
          languages: <String>['Chinese'],
          parodies: <String>['Fate'],
          characters: <String>['Saber'],
        ).diffAgainst(original),
      );

      expect(changes.title, '新标题');
      expect(changes.description, '概要');
      expect(changes.publishedAt, published);
      expect(changes.clearPublishedAt, isFalse);
      expect(changes.contentRating, ContentRating.r18);
      expect(changes.authors, <Author>[Author(name: 'A')]);
      expect(changes.tags, <Tag>[Tag(name: 'T')]);
      expect(changes.languages, <String>['Chinese']);
      expect(changes.parodies, <String>['Fate']);
      expect(changes.characters, <String>['Saber']);
    });

    test('maps isR18 false back to safe content rating', () {
      final Comic original = _comic(contentRating: ContentRating.r18);
      final ComicMetadataDraftChanges changes = _changedFields(
        ComicMetadataForm.fromComic(original)
            .copyWith(isR18: false)
            .diffAgainst(original),
      );
      expect(changes.contentRating, ContentRating.safe);
    });

    test('includes a list only when that list changed', () {
      final Comic original = _comic();
      final ComicMetadataDraftChanges tagsOnly = _changedFields(
        ComicMetadataForm.fromComic(original)
            .addTag('new-tag')
            .diffAgainst(original),
      );
      expect(tagsOnly.tags, <Tag>[Tag(name: 'new-tag')]);
      expect(tagsOnly.parodies, isNull);
      expect(tagsOnly.characters, isNull);

      final ComicMetadataDraftChanges titleOnly = _changedFields(
        ComicMetadataForm.fromComic(original)
            .copyWith(title: '仅改标题')
            .diffAgainst(original),
      );
      expect(titleOnly.title, '仅改标题');
      expect(titleOnly.tags, isNull);
      expect(titleOnly.parodies, isNull);
      expect(titleOnly.characters, isNull);

      final ComicMetadataDraftChanges parodyAndCharacter = _changedFields(
        ComicMetadataForm.fromComic(original)
            .addParody('Fate')
            .addCharacter('Saber')
            .diffAgainst(original),
      );
      expect(parodyAndCharacter.tags, isNull);
      expect(parodyAndCharacter.parodies, <String>['Fate']);
      expect(parodyAndCharacter.characters, <String>['Saber']);
    });
  });
}
