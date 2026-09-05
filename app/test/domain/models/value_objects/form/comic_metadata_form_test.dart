import 'package:hentai_library/domain/models/entity/comic/author.dart';
import 'package:hentai_library/domain/models/entity/comic/comic.dart';
import 'package:hentai_library/domain/models/entity/comic/tag.dart';
import 'package:hentai_library/domain/models/enums.dart';
import 'package:hentai_library/domain/models/value_objects/form/comic_metadata_form.dart';
import 'package:hentai_library/domain/repositories/comic_repository.dart';
import 'package:test/test.dart';

class _RecordingComicRepository implements ComicRepository {
  String? comicId;
  String? title;
  String? description;
  DateTime? publishedAt;
  bool clearPublishedAt = false;
  List<Author>? authors;
  ContentRating? contentRating;
  List<Tag>? tags;
  List<String>? languages;
  List<String>? parodies;
  List<String>? characters;
  int callCount = 0;

  @override
  Future<void> updateUserMeta(
    String comicId, {
    String? title,
    String? description,
    DateTime? publishedAt,
    bool clearPublishedAt = false,
    List<Author>? authors,
    ContentRating? contentRating,
    List<Tag>? tags,
    List<String>? languages,
    List<String>? parodies,
    List<String>? characters,
  }) async {
    callCount += 1;
    this.comicId = comicId;
    this.title = title;
    this.description = description;
    this.publishedAt = publishedAt;
    this.clearPublishedAt = clearPublishedAt;
    this.authors = authors;
    this.contentRating = contentRating;
    this.tags = tags;
    this.languages = languages;
    this.parodies = parodies;
    this.characters = characters;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

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
      final ComicMetadataFormValidation v = ComicMetadataForm(
        title: '  ',
      ).validate();
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

  group('ComicMetadataForm.applyTo', () {
    test('returns Invalid and does not call repository', () async {
      final _RecordingComicRepository repo = _RecordingComicRepository();
      final ComicMetadataApplyResult result = await ComicMetadataForm(
        title: '  ',
      ).applyTo(repo, _comic());

      expect(result, isA<ComicMetadataApplyInvalid>());
      expect(repo.callCount, 0);
    });

    test('only submits changed title field', () async {
      final _RecordingComicRepository repo = _RecordingComicRepository();
      final Comic original = _comic(title: '原标题', description: '简介');
      final ComicMetadataApplyResult result = await ComicMetadataForm.fromComic(
        original,
      ).copyWith(title: '新标题').applyTo(repo, original);

      expect(result, isA<ComicMetadataApplySucceeded>());
      expect(repo.callCount, 1);
      expect(repo.comicId, 'comic-1');
      expect(repo.title, '新标题');
      expect(repo.description, isNull);
      expect(repo.publishedAt, isNull);
      expect(repo.clearPublishedAt, isFalse);
      expect(repo.authors, isNull);
      expect(repo.contentRating, isNull);
      expect(repo.tags, isNull);
    });

    test('skips repository when nothing changed', () async {
      final _RecordingComicRepository repo = _RecordingComicRepository();
      final Comic original = _comic(description: '简介');
      final ComicMetadataApplyResult result = await ComicMetadataForm.fromComic(
        original,
      ).applyTo(repo, original);

      expect(result, isA<ComicMetadataApplySucceeded>());
      expect(repo.callCount, 0);
    });

    test('clears publishedAt only when it changed to empty', () async {
      final _RecordingComicRepository repo = _RecordingComicRepository();
      final DateTime published = DateTime.utc(2020, 5, 1);
      final Comic original = _comic(publishedAt: published);
      final ComicMetadataApplyResult result = await ComicMetadataForm.fromComic(
        original,
      ).copyWith(publishedAt: null).applyTo(repo, original);

      expect(result, isA<ComicMetadataApplySucceeded>());
      expect(repo.callCount, 1);
      expect(repo.publishedAt, isNull);
      expect(repo.clearPublishedAt, isTrue);
      expect(repo.title, isNull);
    });

    test('only submits authors when ordered names change', () async {
      final _RecordingComicRepository repo = _RecordingComicRepository();
      final Comic original = _comic(
        authors: <Author>[
          Author(name: 'A'),
          Author(name: 'B'),
        ],
      );
      final ComicMetadataApplyResult result =
          await ComicMetadataForm.fromComic(original)
              .copyWith(
                authors: <Author>[
                  Author(name: 'B'),
                  Author(name: 'A'),
                ],
              )
              .applyTo(repo, original);

      expect(result, isA<ComicMetadataApplySucceeded>());
      expect(repo.callCount, 1);
      expect(repo.authors?.map((Author a) => a.name).toList(), <String>[
        'B',
        'A',
      ]);
      expect(repo.title, isNull);
      expect(repo.tags, isNull);
    });

    test('only submits languages when ordered names change', () async {
      final _RecordingComicRepository repo = _RecordingComicRepository();
      final Comic original = _comic(languages: <String>['Chinese', 'Japanese']);
      final ComicMetadataApplyResult result =
          await ComicMetadataForm.fromComic(original)
              .copyWith(languages: <String>['Japanese', 'Chinese'])
              .applyTo(repo, original);

      expect(result, isA<ComicMetadataApplySucceeded>());
      expect(repo.callCount, 1);
      expect(repo.languages, <String>['Japanese', 'Chinese']);
      expect(repo.title, isNull);
    });

    test('only submits parodies when ordered names change', () async {
      final _RecordingComicRepository repo = _RecordingComicRepository();
      final Comic original = _comic(parodies: <String>['Fate', '原创']);
      final ComicMetadataApplyResult result = await ComicMetadataForm.fromComic(
        original,
      ).copyWith(parodies: <String>['原创', 'Fate']).applyTo(repo, original);

      expect(result, isA<ComicMetadataApplySucceeded>());
      expect(repo.callCount, 1);
      expect(repo.parodies, <String>['原创', 'Fate']);
      expect(repo.title, isNull);
      expect(repo.languages, isNull);
    });

    test('only submits characters when ordered names change', () async {
      final _RecordingComicRepository repo = _RecordingComicRepository();
      final Comic original = _comic(characters: <String>['Saber', 'Rider']);
      final ComicMetadataApplyResult result =
          await ComicMetadataForm.fromComic(original)
              .copyWith(characters: <String>['Rider', 'Saber'])
              .applyTo(repo, original);

      expect(result, isA<ComicMetadataApplySucceeded>());
      expect(repo.callCount, 1);
      expect(repo.characters, <String>['Rider', 'Saber']);
      expect(repo.title, isNull);
      expect(repo.parodies, isNull);
    });

    test('persists all fields that differ from original', () async {
      final _RecordingComicRepository repo = _RecordingComicRepository();
      final DateTime published = DateTime.utc(2020, 5, 1);
      final Comic original = _comic();
      final ComicMetadataApplyResult result = await ComicMetadataForm(
        title: ' 新标题 ',
        description: ' 概要 ',
        publishedAt: published,
        isR18: true,
        authors: <Author>[Author(name: 'A')],
        tags: <Tag>[Tag(name: 'T')],
        languages: <String>['Chinese'],
        parodies: <String>['Fate'],
        characters: <String>['Saber'],
      ).applyTo(repo, original);

      expect(result, isA<ComicMetadataApplySucceeded>());
      expect(repo.callCount, 1);
      expect(repo.comicId, 'comic-1');
      expect(repo.title, '新标题');
      expect(repo.description, '概要');
      expect(repo.publishedAt, published);
      expect(repo.clearPublishedAt, isFalse);
      expect(repo.contentRating, ContentRating.r18);
      expect(repo.authors, <Author>[Author(name: 'A')]);
      expect(repo.tags, <Tag>[Tag(name: 'T')]);
      expect(repo.languages, <String>['Chinese']);
      expect(repo.parodies, <String>['Fate']);
      expect(repo.characters, <String>['Saber']);
    });

    test('isR18 false maps to safe when original was r18', () async {
      final _RecordingComicRepository repo = _RecordingComicRepository();
      final Comic original = _comic(contentRating: ContentRating.r18);
      await ComicMetadataForm.fromComic(
        original,
      ).copyWith(isR18: false).applyTo(repo, original);
      expect(repo.contentRating, ContentRating.safe);
    });

    test('marks dictionary fields written only when submitted', () async {
      final _RecordingComicRepository repo = _RecordingComicRepository();
      final Comic original = _comic();
      final ComicMetadataApplyResult tagsOnly =
          await ComicMetadataForm.fromComic(
            original,
          ).addTag('new-tag').applyTo(repo, original);
      expect(
        tagsOnly,
        isA<ComicMetadataApplySucceeded>()
            .having(
              (ComicMetadataApplySucceeded r) => r.tagsWritten,
              'tagsWritten',
              isTrue,
            )
            .having(
              (ComicMetadataApplySucceeded r) => r.parodiesWritten,
              'parodiesWritten',
              isFalse,
            )
            .having(
              (ComicMetadataApplySucceeded r) => r.charactersWritten,
              'charactersWritten',
              isFalse,
            ),
      );

      final ComicMetadataApplyResult titleOnly =
          await ComicMetadataForm.fromComic(
            original,
          ).copyWith(title: '仅改标题').applyTo(repo, original);
      expect(
        titleOnly,
        isA<ComicMetadataApplySucceeded>()
            .having(
              (ComicMetadataApplySucceeded r) => r.tagsWritten,
              'tagsWritten',
              isFalse,
            )
            .having(
              (ComicMetadataApplySucceeded r) => r.parodiesWritten,
              'parodiesWritten',
              isFalse,
            )
            .having(
              (ComicMetadataApplySucceeded r) => r.charactersWritten,
              'charactersWritten',
              isFalse,
            ),
      );

      final ComicMetadataApplyResult parodyAndCharacter =
          await ComicMetadataForm.fromComic(
            original,
          ).addParody('Fate').addCharacter('Saber').applyTo(repo, original);
      expect(
        parodyAndCharacter,
        isA<ComicMetadataApplySucceeded>()
            .having(
              (ComicMetadataApplySucceeded r) => r.tagsWritten,
              'tagsWritten',
              isFalse,
            )
            .having(
              (ComicMetadataApplySucceeded r) => r.parodiesWritten,
              'parodiesWritten',
              isTrue,
            )
            .having(
              (ComicMetadataApplySucceeded r) => r.charactersWritten,
              'charactersWritten',
              isTrue,
            ),
      );
    });

    test('no repository call leaves dictionary flags false', () async {
      final _RecordingComicRepository repo = _RecordingComicRepository();
      final Comic original = _comic(tags: <Tag>[Tag(name: 'T')]);
      final ComicMetadataApplyResult result = await ComicMetadataForm.fromComic(
        original,
      ).applyTo(repo, original);

      expect(repo.callCount, 0);
      expect(
        result,
        isA<ComicMetadataApplySucceeded>()
            .having(
              (ComicMetadataApplySucceeded r) => r.tagsWritten,
              'tagsWritten',
              isFalse,
            )
            .having(
              (ComicMetadataApplySucceeded r) => r.parodiesWritten,
              'parodiesWritten',
              isFalse,
            )
            .having(
              (ComicMetadataApplySucceeded r) => r.charactersWritten,
              'charactersWritten',
              isFalse,
            ),
      );
    });
  });
}
