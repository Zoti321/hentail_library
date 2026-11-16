import 'package:hentai_library/features/comic_trash/application/comic_trash_service.dart';
import 'package:hentai_library/shared/domain/events/events.dart';
import 'package:hentai_library/features/comic_trash/public.dart';
import 'package:test/test.dart';

class _RecordingEventPublisher implements DomainEventPublisher {
  final List<DomainEvent> events = <DomainEvent>[];

  @override
  void publish(DomainEvent event) => events.add(event);
}

class _RecordingComicRepository implements ComicTrashRepository {
  final List<String> calls = <String>[];
  List<String> trashedIds = <String>[];
  List<String>? remainingAfterPurge;
  ComicPurgeResult? purgeResult;
  bool failPurge = false;
  bool failPostPurgeList = false;
  bool purged = false;

  @override
  Future<void> trashByIds(List<String> comicIds) async {
    calls.add('trash:${comicIds.join(',')}');
  }

  @override
  Future<void> restoreByIds(List<String> comicIds) async {
    calls.add('restore:${comicIds.join(',')}');
  }

  @override
  Future<ComicPurgeResult> purgeByIds(List<String> comicIds) async {
    calls.add('purge:${comicIds.join(',')}');
    if (failPurge) throw StateError('purge');
    purged = true;
    trashedIds = remainingAfterPurge ?? trashedIds;
    return purgeResult ??
        (succeeded: comicIds.length, failed: 0, errorSamples: const <String>[]);
  }

  @override
  Future<List<String>> listTrashedIds() async {
    calls.add('list');
    if (purged && failPostPurgeList) throw StateError('list');
    return trashedIds;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _RecordingNativeReaderPort implements ComicTrashNativeReaderPort {
  _RecordingNativeReaderPort(this.calls);

  final List<String> calls;

  @override
  Future<void> closeComic(String comicId) async {
    calls.add('close:$comicId');
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late _RecordingComicRepository comicRepo;
  late _RecordingEventPublisher events;
  late ComicTrashService service;

  setUp(() {
    comicRepo = _RecordingComicRepository();
    events = _RecordingEventPublisher();
    service = ComicTrashService(
      comicRepository: comicRepo,
      readerSessionPort: _RecordingNativeReaderPort(comicRepo.calls),
      events: events,
    );
  });

  test('publishes trashed / restored facts after write', () async {
    await service.trashComics(<String>['c1']);
    await service.restoreComics(<String>['c1']);

    expect(events.events, hasLength(2));
    expect(events.events.first, isA<ComicsTrashed>());
    expect(events.events.last, isA<ComicsRestored>());
  });

  test('empty ids are no-ops for trash / restore / purge', () async {
    await service.trashComics(const <String>[]);
    await service.restoreComics(const <String>[]);
    final ComicPurgeOutcome outcome = await service.purgeComics(
      const <String>[],
    );

    expect(comicRepo.calls, isEmpty);
    expect(outcome.result.succeeded, 0);
    expect(outcome.result.failed, 0);
  });

  test('trashComics closes reader sessions before trashing', () async {
    await service.trashComics(<String>['c1', 'c2', 'c1']);

    expect(comicRepo.calls, <String>['close:c1', 'close:c2', 'trash:c1,c2']);
  });

  test('restoreComics does not touch reader sessions', () async {
    await service.restoreComics(<String>['c1']);

    expect(comicRepo.calls, <String>['restore:c1']);
  });

  test('purgeComics closes sessions then purges', () async {
    final ComicPurgeOutcome outcome = await service.purgeComics(<String>['c1']);

    expect(comicRepo.calls, <String>['close:c1', 'purge:c1', 'list']);
    expect(outcome.result.succeeded, 1);
    expect(outcome.purgedIds, ['c1']);
  });

  test('purgeAll snapshots targets, closes sessions and identifies only removed IDs', () async {
    comicRepo
      ..trashedIds = ['c1', 'c2', 'c1']
      ..remainingAfterPurge = ['c2', 'unrelated']
      ..purgeResult = (succeeded: 1, failed: 1, errorSamples: ['c2']);
    final outcome = await service.purgeAll();
    expect(comicRepo.calls, [
      'list',
      'close:c1',
      'close:c2',
      'purge:c1,c2',
      'list',
    ]);
    expect(outcome.result, comicRepo.purgeResult);
    expect(outcome.purgedIds, ['c1']);
    expect(events.events, isEmpty);
  });

  test('no successful purges skip the remaining-trash read', () async {
    comicRepo.purgeResult = (succeeded: 0, failed: 1, errorSamples: ['locked']);
    final outcome = await service.purgeComics(['c1']);
    expect(comicRepo.calls, ['close:c1', 'purge:c1']);
    expect(outcome.purgedIds, isEmpty);
    expect(outcome.result, comicRepo.purgeResult);
  });

  test(
    'purge failure skips reconciliation and propagates without retry',
    () async {
      comicRepo.failPurge = true;
      await expectLater(service.purgeComics(['c1']), throwsStateError);
      expect(comicRepo.calls, ['close:c1', 'purge:c1']);
      expect(comicRepo.purged, isFalse);
    },
  );

  test(
    'post-purge read failure propagates without repeating the committed purge',
    () async {
      comicRepo.failPostPurgeList = true;
      await expectLater(service.purgeComics(['c1']), throwsStateError);
      expect(comicRepo.calls, ['close:c1', 'purge:c1', 'list']);
      expect(comicRepo.purged, isTrue);
    },
  );
}
