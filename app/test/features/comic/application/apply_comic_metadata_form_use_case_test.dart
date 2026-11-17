import 'package:hentai_library/features/comic/application/apply_comic_metadata_form_use_case.dart';
import 'package:hentai_library/features/comic/domain/comic.dart';
import 'package:hentai_library/features/comic/domain/repositories/comic_user_metadata_repository.dart';
import 'package:hentai_library/features/comic/domain/value_objects/content_rating.dart';
import 'package:hentai_library/features/comic/domain/value_objects/comic_metadata_form.dart';
import 'package:hentai_library/shared/domain/events/events.dart';
import 'package:hentai_library/shared/domain/models/enums.dart';
import 'package:hentai_library/features/comic_metadata/public/comic_metadata_entities.dart';
import 'package:test/test.dart';

class _RecordingRepository implements ComicUserMetadataRepository {
  _RecordingRepository(this.calls);

  final List<String> calls;
  bool fail = false;

  @override
  Future<void> updateUserMeta(
    String comicId, {
    String? title,
    String? description,
    DateTime? publishedAt,
    bool clearPublishedAt = false,
    List<String>? authors,
    ContentRating? contentRating,
    List<Tag>? tags,
    List<String>? languages,
    List<String>? parodies,
    List<String>? characters,
  }) async {
    calls.add('write:$comicId');
    if (fail) throw StateError('write failed');
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _RecordingEvents implements DomainEventPublisher {
  _RecordingEvents(this.calls);

  final List<String> calls;
  final List<DomainEvent> events = <DomainEvent>[];

  @override
  void publish(DomainEvent event) {
    calls.add('publish');
    events.add(event);
  }
}

Comic _comic() {
  final DateTime now = DateTime.utc(2024, 1, 1);
  return Comic.restore(
    comicId: 'comic-1',
    path: '/library/comic-1',
    resourceType: ResourceType.dir,
    resourceSize: 0,
    createdAt: now,
    lastUpdatedAt: now,
    title: 'Original',
    pageCount: 1,
  );
}

void main() {
  test(
    'persists changed metadata before publishing its committed fact',
    () async {
      final calls = <String>[];
      final repository = _RecordingRepository(calls);
      final events = _RecordingEvents(calls);
      final comic = _comic();
      final useCase = ApplyComicMetadataFormUseCase(
        repository: repository,
        events: events,
      );

      final result = await useCase(
        ComicMetadataForm.fromComic(comic).copyWith(title: 'Updated'),
        comic,
      );

      expect(result, isA<ComicMetadataApplySucceeded>());
      expect((result as ComicMetadataApplySucceeded).persisted, isTrue);
      expect(calls, <String>['write:comic-1', 'publish']);
      expect(events.events, hasLength(1));
      final persisted = events.events.single as ComicMetadataPersisted;
      expect(persisted.dictionariesWritten, isFalse);
    },
  );

  for (final tagsOnly in <bool>[true, false]) {
    test('preserves dictionary write facts: tagsOnly=$tagsOnly', () async {
      final calls = <String>[];
      final events = _RecordingEvents(calls);
      final comic = _comic();
      final useCase = ApplyComicMetadataFormUseCase(
        repository: _RecordingRepository(calls),
        events: events,
      );
      final form = ComicMetadataForm.fromComic(comic);
      final result = await useCase(
        tagsOnly
            ? form.addTag('new-tag')
            : form.addParody('Fate').addCharacter('Saber'),
        comic,
      );

      expect(result, isA<ComicMetadataApplySucceeded>());
      final succeeded = result as ComicMetadataApplySucceeded;
      expect(succeeded.persisted, isTrue);
      expect(succeeded.tagsWritten, tagsOnly);
      expect(succeeded.parodiesWritten, !tagsOnly);
      expect(succeeded.charactersWritten, !tagsOnly);
      expect(calls, <String>['write:comic-1', 'publish']);
      final persisted = events.events.single as ComicMetadataPersisted;
      expect(persisted.tagsWritten, tagsOnly);
      expect(persisted.parodiesWritten, !tagsOnly);
      expect(persisted.charactersWritten, !tagsOnly);
      expect(persisted.dictionariesWritten, isTrue);
    });
  }

  test('invalid and unchanged forms do not write or publish', () async {
    final calls = <String>[];
    final repository = _RecordingRepository(calls);
    final events = _RecordingEvents(calls);
    final comic = _comic();
    final useCase = ApplyComicMetadataFormUseCase(
      repository: repository,
      events: events,
    );

    final invalid = await useCase(
      ComicMetadataForm.fromComic(comic).copyWith(title: '  '),
      comic,
    );
    final unchanged = await useCase(ComicMetadataForm.fromComic(comic), comic);

    expect(invalid, isA<ComicMetadataApplyInvalid>());
    expect(unchanged, isA<ComicMetadataApplySucceeded>());
    expect((unchanged as ComicMetadataApplySucceeded).persisted, isFalse);
    expect(calls, isEmpty);
    expect(events.events, isEmpty);
  });

  test(
    'write failure propagates without publishing a committed fact',
    () async {
      final calls = <String>[];
      final repository = _RecordingRepository(calls)..fail = true;
      final events = _RecordingEvents(calls);
      final comic = _comic();
      final useCase = ApplyComicMetadataFormUseCase(
        repository: repository,
        events: events,
      );

      await expectLater(
        useCase(
          ComicMetadataForm.fromComic(comic).copyWith(title: 'Updated'),
          comic,
        ),
        throwsStateError,
      );

      expect(calls, <String>['write:comic-1']);
      expect(events.events, isEmpty);
    },
  );
}
