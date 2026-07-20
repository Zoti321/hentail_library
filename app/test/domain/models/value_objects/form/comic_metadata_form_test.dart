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
  List<Author>? authors;
  ContentRating? contentRating;
  List<Tag>? tags;
  int callCount = 0;

  @override
  Future<void> updateUserMeta(
    String comicId, {
    String? title,
    String? description,
    DateTime? publishedAt,
    List<Author>? authors,
    ContentRating? contentRating,
    List<Tag>? tags,
  }) async {
    callCount += 1;
    this.comicId = comicId;
    this.title = title;
    this.description = description;
    this.publishedAt = publishedAt;
    this.authors = authors;
    this.contentRating = contentRating;
    this.tags = tags;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Comic _comic({
  String title = '原标题',
  String? description,
  ContentRating contentRating = ContentRating.safe,
  List<Author> authors = const <Author>[],
  List<Tag> tags = const <Tag>[],
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
    contentRating: contentRating,
    authors: authors,
    tags: tags,
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
      ).applyTo(repo, 'comic-1');

      expect(result, isA<ComicMetadataApplyInvalid>());
      expect(repo.callCount, 0);
    });

    test('persists normalized fields and content rating', () async {
      final _RecordingComicRepository repo = _RecordingComicRepository();
      final DateTime published = DateTime.utc(2020, 5, 1);
      final ComicMetadataApplyResult result = await ComicMetadataForm(
        title: ' 新标题 ',
        description: ' 概要 ',
        publishedAt: published,
        isR18: true,
        authors: <Author>[Author(name: 'A')],
        tags: <Tag>[Tag(name: 'T')],
      ).applyTo(repo, 'comic-1');

      expect(result, isA<ComicMetadataApplySucceeded>());
      expect(repo.callCount, 1);
      expect(repo.comicId, 'comic-1');
      expect(repo.title, '新标题');
      expect(repo.description, '概要');
      expect(repo.publishedAt, published);
      expect(repo.contentRating, ContentRating.r18);
      expect(repo.authors, <Author>[Author(name: 'A')]);
      expect(repo.tags, <Tag>[Tag(name: 'T')]);
    });

    test('isR18 false maps to safe content rating', () async {
      final _RecordingComicRepository repo = _RecordingComicRepository();
      await ComicMetadataForm(title: 't', isR18: false).applyTo(repo, 'id');
      expect(repo.contentRating, ContentRating.safe);
    });
  });
}
