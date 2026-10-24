import 'package:hentai_library/features/library_browse/presentation/view_models/comic_metadata_apply.dart';
import 'package:hentai_library/shared/domain/library/library_change.dart';
import 'package:hentai_library/shared/domain/models/entity/comic/comic.dart';
import 'package:hentai_library/shared/domain/models/entity/comic/tag.dart';
import 'package:hentai_library/shared/domain/models/enums.dart';
import 'package:hentai_library/shared/domain/models/value_objects/form/comic_metadata_form.dart';
import 'package:hentai_library/features/library_browse/domain/comic_user_metadata_repository.dart';
import 'package:test/test.dart';

class _RecordingComicRepository implements ComicUserMetadataRepository {
  int callCount = 0;

  @override
  Future<void> updateUserMeta(
    String comicId, {
    String? title,
    String? description,
    DateTime? publishedAt,
    bool clearPublishedAt = false,
    List? authors,
    ContentRating? contentRating,
    List? tags,
    List<String>? languages,
    List<String>? parodies,
    List<String>? characters,
  }) async {
    callCount += 1;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Comic _comic({List<Tag> tags = const <Tag>[]}) {
  final DateTime now = DateTime.utc(2024, 1, 1);
  return Comic(
    comicId: 'comic-1',
    path: '/library/comic-1',
    resourceType: ResourceType.dir,
    resourceSize: 0,
    createdAt: now,
    lastUpdatedAt: now,
    title: '原标题',
    contentRating: ContentRating.safe,
    authors: const [],
    tags: tags,
    languages: const [],
    parodies: const [],
    characters: const [],
    pageCount: 1,
  );
}

void main() {
  group('applyComicMetadataForm', () {
    test('publishes tag write and metadata save when tags change', () async {
      final _RecordingComicRepository repo = _RecordingComicRepository();
      final Comic original = _comic();
      final List<LibraryChange> published = <LibraryChange>[];
      var notifyCount = 0;

      final ComicMetadataApplyResult result = await applyComicMetadataForm(
        repo,
        ComicMetadataForm.fromComic(original).addTag('new-tag'),
        original,
        publish: published.add,
        notifyExternalChange: () => notifyCount += 1,
      );

      expect(result, isA<ComicMetadataApplySucceeded>());
      expect(repo.callCount, 1);
      expect(published, hasLength(1));
      expect(published.single.tagsWritten, isTrue);
      expect(published.single.parodiesWritten, isFalse);
      expect(published.single.metadataSaved, isTrue);
      expect(notifyCount, 1);
    });

    test('publishes parody and character writes together', () async {
      final _RecordingComicRepository repo = _RecordingComicRepository();
      final Comic original = _comic();
      final List<LibraryChange> published = <LibraryChange>[];

      await applyComicMetadataForm(
        repo,
        ComicMetadataForm.fromComic(original)
            .addParody('Fate')
            .addCharacter('Saber'),
        original,
        publish: published.add,
        notifyExternalChange: () {},
      );

      expect(published.single.parodiesWritten, isTrue);
      expect(published.single.charactersWritten, isTrue);
      expect(published.single.tagsWritten, isFalse);
      expect(published.single.metadataSaved, isTrue);
    });

    test(
      'title-only change publishes save without dictionary writes',
      () async {
        final _RecordingComicRepository repo = _RecordingComicRepository();
        final Comic original = _comic();
        final List<LibraryChange> published = <LibraryChange>[];
        var notifyCount = 0;

        await applyComicMetadataForm(
          repo,
          ComicMetadataForm.fromComic(original).copyWith(title: '新标题'),
          original,
          publish: published.add,
          notifyExternalChange: () => notifyCount += 1,
        );

        expect(repo.callCount, 1);
        expect(published.single.dictionariesWritten, isFalse);
        expect(published.single.metadataSaved, isTrue);
        expect(notifyCount, 1);
      },
    );

    test('does not publish or notify when form is invalid', () async {
      final _RecordingComicRepository repo = _RecordingComicRepository();
      final Comic original = _comic();
      final List<LibraryChange> published = <LibraryChange>[];
      var notifyCount = 0;

      final ComicMetadataApplyResult result = await applyComicMetadataForm(
        repo,
        ComicMetadataForm.fromComic(original).copyWith(title: '   '),
        original,
        publish: published.add,
        notifyExternalChange: () => notifyCount += 1,
      );

      expect(result, isA<ComicMetadataApplyInvalid>());
      expect(repo.callCount, 0);
      expect(published, isEmpty);
      expect(notifyCount, 0);
    });

    test('does not notify external change when nothing persisted', () async {
      final _RecordingComicRepository repo = _RecordingComicRepository();
      final Comic original = _comic();
      final List<LibraryChange> published = <LibraryChange>[];
      var notifyCount = 0;

      final ComicMetadataApplyResult result = await applyComicMetadataForm(
        repo,
        ComicMetadataForm.fromComic(original),
        original,
        publish: published.add,
        notifyExternalChange: () => notifyCount += 1,
      );

      expect(result, isA<ComicMetadataApplySucceeded>());
      expect(repo.callCount, 0);
      expect(published.single.metadataSaved, isFalse);
      expect(notifyCount, 0);
    });
  });
}
