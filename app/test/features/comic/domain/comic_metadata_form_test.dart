import 'package:hentai_library/shared/domain/models/value_objects/author_ref.dart';
import 'package:hentai_library/features/comic/domain/comic.dart';
import 'package:hentai_library/shared/domain/models/entity/comic/tag.dart';
import 'package:hentai_library/shared/domain/models/enums.dart';
import 'package:hentai_library/features/comic/domain/comic_metadata_form.dart';
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

void main() {
  group('ComicMetadataForm.fromComic', () {
    test('maps fields and r18 content rating', () {
      final ComicMetadataForm form = ComicMetadataForm.fromComic(
        _comic(
          description: '简介',
          contentRating: ContentRating.r18,
          authors: <AuthorRef>[AuthorRef.byName('A')],
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
      expect(form.authors, <AuthorRef>[AuthorRef.byName('A')]);
    });

    test('removeAuthor / addTag / removeTag', () {
      ComicMetadataForm form = ComicMetadataForm(
        title: 't',
        authors: <AuthorRef>[AuthorRef.byName('A'), AuthorRef.byName('B')],
        tags: <Tag>[Tag(name: 'X')],
      );
      form = form.removeAuthor('A').addTag('Y').removeTag('X');
      expect(form.authors.single.name, 'B');
      expect(form.tags.single.name, 'Y');
    });
  });
}
