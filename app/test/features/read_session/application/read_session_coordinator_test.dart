import 'package:hentai_library/shared/domain/models/entity/comic/comic.dart';
import 'package:hentai_library/shared/domain/models/enums.dart';
import 'package:hentai_library/shared/domain/ports/reading_history_command_port.dart';
import 'package:hentai_library/features/read_session/domain/read_session.dart';
import 'package:hentai_library/features/read_session/application/read_session_coordinator.dart';
import 'package:hentai_library/features/read_session/application/reader_session_service.dart';
import 'package:test/test.dart';

class _RecordingReadingHistoryCommands implements ReadingHistoryCommandPort {
  final List<({String comicId, String title, int pageIndex})> records =
      <({String comicId, String title, int pageIndex})>[];

  @override
  Future<void> recordReading({
    required String comicId,
    required String title,
    required DateTime lastReadTime,
    required int pageIndex,
  }) async {
    records.add((comicId: comicId, title: title, pageIndex: pageIndex));
  }

  @override
  Future<int?> readResumePageIndex(String comicId) async => null;
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
  late _RecordingReadingHistoryCommands readingCommands;
  late _RecordingReaderSessionService sessionService;
  late ReadSessionCoordinator coordinator;

  setUp(() {
    readingCommands = _RecordingReadingHistoryCommands();
    sessionService = _RecordingReaderSessionService();
    coordinator = ReadSessionCoordinator(
      sessionService: sessionService,
      readingHistoryCommands: readingCommands,
    );
  });

  test('incognito beginReadSession is no-op', () async {
    await coordinator.beginReadSession(
      comic: _comic(),
      incognito: true,
      initialPageIndex: 3,
    );

    expect(readingCommands.records, isEmpty);
    expect(coordinator.hasActiveSession, isFalse);
  });

  test('beginReadSession writes only comic history', () async {
    await coordinator.beginReadSession(comic: _comic(), initialPageIndex: 2);

    expect(readingCommands.records, hasLength(1));
    expect(readingCommands.records.single.comicId, 'c1');
    expect(readingCommands.records.single.pageIndex, 2);
    expect(coordinator.hasActiveSession, isTrue);
  });

  test('updatePage and flushProgress persist latest page', () async {
    await coordinator.beginReadSession(comic: _comic(), initialPageIndex: 1);
    readingCommands.records.clear();

    coordinator.updatePage(7);
    await coordinator.flushProgress();

    expect(readingCommands.records, hasLength(1));
    expect(readingCommands.records.single.pageIndex, 7);
  });

  test('endSession clears active session after flush', () async {
    await coordinator.beginReadSession(comic: _comic(), initialPageIndex: 3);
    readingCommands.records.clear();

    coordinator.updatePage(5);
    await coordinator.endSession();

    expect(readingCommands.records, hasLength(1));
    expect(readingCommands.records.single.pageIndex, 5);
    expect(coordinator.hasActiveSession, isFalse);
  });

  test('exitReadSession flushes history and closes I/O session', () async {
    await coordinator.beginReadSession(comic: _comic(), initialPageIndex: 2);
    readingCommands.records.clear();

    coordinator.updatePage(6);
    await coordinator.exitReadSession(
      comicId: 'c1',
      incognito: false,
      currentPageIndex: 6,
    );

    expect(readingCommands.records, hasLength(1));
    expect(readingCommands.records.single.pageIndex, 6);
    expect(coordinator.hasActiveSession, isFalse);
    expect(sessionService.closedComicIds, <String>['c1']);
  });

  test('exitReadSession skips history when incognito', () async {
    await coordinator.exitReadSession(
      comicId: 'c1',
      incognito: true,
      currentPageIndex: 3,
    );

    expect(readingCommands.records, isEmpty);
    expect(sessionService.closedComicIds, <String>['c1']);
  });

  test(
    'prepareSeriesSwitch returns next session starting from first page',
    () async {
      await coordinator.beginReadSession(comic: _comic(), initialPageIndex: 3);
      readingCommands.records.clear();

      final SeriesSwitchPlan plan = await coordinator.prepareSeriesSwitch(
        currentSession: const ReadSessionRouteParams(comicId: 'c1'),
        targetComicId: 'c2',
        currentPageIndex: 8,
      );

      expect(readingCommands.records, hasLength(1));
      expect(readingCommands.records.single.pageIndex, 8);
      expect(coordinator.hasActiveSession, isFalse);
      expect(sessionService.closedComicIds, <String>['c1']);
      expect(plan.closeComicId, 'c1');
      expect(plan.targetComicId, 'c2');
      expect(plan.nextSession.comicId, 'c2');
      expect(plan.nextSession.startFromFirstPage, isTrue);
    },
  );
}
