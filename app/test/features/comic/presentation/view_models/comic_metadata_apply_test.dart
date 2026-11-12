import 'package:hentai_library/features/comic/application/comic_metadata_service.dart';
import 'package:hentai_library/shared/domain/events/events.dart';
import 'package:hentai_library/features/comic/domain/comic.dart';
import 'package:hentai_library/features/comic_metadata/public/comic_metadata_entities.dart';
import 'package:hentai_library/shared/domain/models/enums.dart';
import 'package:hentai_library/features/comic/domain/value_objects/comic_metadata_form.dart';
import 'package:hentai_library/features/comic/domain/repositories/comic_user_metadata_repository.dart';
import 'package:test/test.dart';

class _RecordingEventPublisher implements DomainEventPublisher {
  final List<DomainEvent> events = <DomainEvent>[];

  @override
  void publish(DomainEvent event) => events.add(event);
}

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
  return Comic.restore(
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
      final _RecordingEventPublisher events = _RecordingEventPublisher();
      final Comic original = _comic();

      final ComicMetadataApplyResult result = await applyComicMetadataForm(
        repo,
        ComicMetadataForm.fromComic(original).addTag('new-tag'),
        original,
        events: events,
      );

      expect(result, isA<ComicMetadataApplySucceeded>());
      expect(repo.callCount, 1);
      expect(events.events, hasLength(1));
      final ComicMetadataPersisted persisted =
          events.events.single as ComicMetadataPersisted;
      expect(persisted.tagsWritten, isTrue);
      expect(persisted.parodiesWritten, isFalse);
      expect(persisted.dictionariesWritten, isTrue);
    });

    test('publishes parody and character writes together', () async {
      final _RecordingComicRepository repo = _RecordingComicRepository();
      final _RecordingEventPublisher events = _RecordingEventPublisher();
      final Comic original = _comic();

      await applyComicMetadataForm(
        repo,
        ComicMetadataForm.fromComic(original)
            .addParody('Fate')
            .addCharacter('Saber'),
        original,
        events: events,
      );

      final ComicMetadataPersisted persisted =
          events.events.single as ComicMetadataPersisted;
      expect(persisted.parodiesWritten, isTrue);
      expect(persisted.charactersWritten, isTrue);
      expect(persisted.tagsWritten, isFalse);
      expect(persisted.dictionariesWritten, isTrue);
    });

    test(
      'title-only change publishes save without dictionary writes',
      () async {
        final _RecordingComicRepository repo = _RecordingComicRepository();
        final _RecordingEventPublisher events = _RecordingEventPublisher();
        final Comic original = _comic();

        await applyComicMetadataForm(
          repo,
          ComicMetadataForm.fromComic(original).copyWith(title: '新标题'),
          original,
          events: events,
        );

        expect(repo.callCount, 1);
        final ComicMetadataPersisted persisted =
            events.events.single as ComicMetadataPersisted;
        expect(persisted.dictionariesWritten, isFalse);
      },
    );

    test('does not publish when form is invalid', () async {
      final _RecordingComicRepository repo = _RecordingComicRepository();
      final _RecordingEventPublisher events = _RecordingEventPublisher();
      final Comic original = _comic();

      final ComicMetadataApplyResult result = await applyComicMetadataForm(
        repo,
        ComicMetadataForm.fromComic(original).copyWith(title: '   '),
        original,
        events: events,
      );

      expect(result, isA<ComicMetadataApplyInvalid>());
      expect(repo.callCount, 0);
      expect(events.events, isEmpty);
    });

    test('does not publish when unchanged', () async {
      final _RecordingComicRepository repo = _RecordingComicRepository();
      final _RecordingEventPublisher events = _RecordingEventPublisher();
      final Comic original = _comic();

      final ComicMetadataApplyResult result = await applyComicMetadataForm(
        repo,
        ComicMetadataForm.fromComic(original),
        original,
        events: events,
      );

      expect(result, isA<ComicMetadataApplySucceeded>());
      expect(repo.callCount, 0);
      expect(events.events, isEmpty);
    });
  });
}
