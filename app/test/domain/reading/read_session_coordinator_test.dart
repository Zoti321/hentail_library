import 'package:hentai_library/domain/models/entity/comic/comic.dart';
import 'package:hentai_library/domain/models/entity/reading_history.dart';
import 'package:hentai_library/domain/models/enums.dart';
import 'package:hentai_library/domain/reading/read_session.dart';
import 'package:hentai_library/domain/reading/read_session_coordinator.dart';
import 'package:hentai_library/domain/reading/reader_session_service.dart';
import 'package:hentai_library/domain/repositories/reading_history_repository.dart';
import 'package:test/test.dart';

class _RecordingReadingHistoryRepo implements ReadingHistoryRepository {
  final List<ReadingHistory> records = <ReadingHistory>[];

  @override
  Future<void> recordReading(ReadingHistory history) async {
    records.add(history);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _RecordingReaderSessionService implements ReaderSessionService {
  _RecordingReaderSessionService() : closedComicIds = <String>[];

  final List<String> closedComicIds;

  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #close) {
      closedComicIds.add(invocation.positionalArguments.first as String);
      return Future<void>.value();
    }
    return super.noSuchMethod(invocation);
  }
}

Comic _comic({String id = 'c1', String title = 'Test Comic'}) {
  final DateTime now = DateTime.utc(2026, 1, 1);
  return Comic(
    comicId: id,
    path: '/tmp/$id',
    resourceType: ResourceType.zip,
    resourceSize: 1024,
    createdAt: now,
    lastUpdatedAt: now,
    title: title,
    pageCount: 10,
  );
}

void main() {
  late _RecordingReadingHistoryRepo readingRepo;
  late _RecordingReaderSessionService sessionService;
  late ReadSessionCoordinator coordinator;

  setUp(() {
    readingRepo = _RecordingReadingHistoryRepo();
    sessionService = _RecordingReaderSessionService();
    coordinator = ReadSessionCoordinator(
      sessionService: sessionService,
      readingHistoryRepo: readingRepo,
    );
  });

  test('incognito beginReadSession is no-op', () async {
    await coordinator.beginReadSession(
      comic: _comic(),
      incognito: true,
      initialPageIndex: 3,
    );

    expect(readingRepo.records, isEmpty);
    expect(coordinator.hasActiveSession, isFalse);
  });

  test('beginReadSession writes only comic history', () async {
    await coordinator.beginReadSession(comic: _comic(), initialPageIndex: 2);

    expect(readingRepo.records, hasLength(1));
    expect(readingRepo.records.single.comicId, 'c1');
    expect(readingRepo.records.single.pageIndex, 2);
    expect(coordinator.hasActiveSession, isTrue);
  });

  test('updatePage and flushProgress persist latest page', () async {
    await coordinator.beginReadSession(comic: _comic(), initialPageIndex: 1);
    readingRepo.records.clear();

    coordinator.updatePage(7);
    await coordinator.flushProgress();

    expect(readingRepo.records, hasLength(1));
    expect(readingRepo.records.single.pageIndex, 7);
  });

  test('endSession clears active session after flush', () async {
    await coordinator.beginReadSession(comic: _comic(), initialPageIndex: 3);
    readingRepo.records.clear();

    coordinator.updatePage(5);
    await coordinator.endSession();

    expect(readingRepo.records, hasLength(1));
    expect(readingRepo.records.single.pageIndex, 5);
    expect(coordinator.hasActiveSession, isFalse);
  });

  test('exitReadSession flushes history and closes I/O session', () async {
    await coordinator.beginReadSession(comic: _comic(), initialPageIndex: 2);
    readingRepo.records.clear();

    coordinator.updatePage(6);
    await coordinator.exitReadSession(
      comicId: 'c1',
      incognito: false,
      currentPageIndex: 6,
    );

    expect(readingRepo.records, hasLength(1));
    expect(readingRepo.records.single.pageIndex, 6);
    expect(coordinator.hasActiveSession, isFalse);
    expect(sessionService.closedComicIds, <String>['c1']);
  });

  test('exitReadSession skips history when incognito', () async {
    await coordinator.exitReadSession(
      comicId: 'c1',
      incognito: true,
      currentPageIndex: 3,
    );

    expect(readingRepo.records, isEmpty);
    expect(sessionService.closedComicIds, <String>['c1']);
  });

  test(
    'prepareSeriesSwitch returns next session starting from first page',
    () async {
      await coordinator.beginReadSession(comic: _comic(), initialPageIndex: 3);
      readingRepo.records.clear();

      final SeriesSwitchPlan plan = await coordinator.prepareSeriesSwitch(
        currentSession: const ReadSessionRouteParams(comicId: 'c1'),
        targetComicId: 'c2',
        currentPageIndex: 8,
      );

      expect(readingRepo.records, hasLength(1));
      expect(readingRepo.records.single.pageIndex, 8);
      expect(coordinator.hasActiveSession, isFalse);
      expect(sessionService.closedComicIds, <String>['c1']);
      expect(plan.closeComicId, 'c1');
      expect(plan.targetComicId, 'c2');
      expect(plan.nextSession.comicId, 'c2');
      expect(plan.nextSession.startFromFirstPage, isTrue);
    },
  );
}
