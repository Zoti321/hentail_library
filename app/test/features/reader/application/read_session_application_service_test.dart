import 'package:hentai_library/features/reader/domain/reader_comic_ref.dart';
import 'package:hentai_library/shared/domain/models/enums.dart';
import 'package:hentai_library/shared/domain/ports/reading_history_command_port.dart';
import 'package:hentai_library/features/reading_stats/public.dart';
import 'package:hentai_library/features/reader/application/open_reader_args.dart';
import 'package:hentai_library/features/reader/application/read_session_application_service.dart';
import 'package:hentai_library/features/reader/application/open_read_session_service.dart';
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

class _RecordingActivityCommands implements RecordReadSessionActivityPort {
  final List<
    ({
      String comicId,
      bool incognito,
      Duration foregroundElapsed,
      int pageIndex,
      int pageCount,
    })
  >
  records =
      <
        ({
          String comicId,
          bool incognito,
          Duration foregroundElapsed,
          int pageIndex,
          int pageCount,
        })
      >[];

  @override
  Future<void> record({
    required String comicId,
    required bool incognito,
    required Duration foregroundElapsed,
    required int pageIndex,
    required int pageCount,
  }) async {
    records.add((
      comicId: comicId,
      incognito: incognito,
      foregroundElapsed: foregroundElapsed,
      pageIndex: pageIndex,
      pageCount: pageCount,
    ));
  }
}

class _RecordingOpenReadSessionService implements OpenReadSessionService {
  _RecordingOpenReadSessionService() : closedComicIds = <String>[];

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

ReaderComicRef _comic({String id = 'c1', String title = 'Test Comic'}) {
  return ReaderComicRef(
    comicId: id,
    path: '/tmp/$id',
    resourceType: ResourceType.zip,
    title: title,
    pageCount: 10,
  );
}

void main() {
  late _RecordingReadingHistoryCommands readingCommands;
  late _RecordingActivityCommands activityCommands;
  late _RecordingOpenReadSessionService sessionService;
  late ReadSessionApplicationService coordinator;
  late DateTime now;

  setUp(() {
    readingCommands = _RecordingReadingHistoryCommands();
    activityCommands = _RecordingActivityCommands();
    sessionService = _RecordingOpenReadSessionService();
    now = DateTime.utc(2026, 1, 1, 12);
    coordinator = ReadSessionApplicationService(
      sessionService: sessionService,
      readingHistoryCommands: readingCommands,
      activityCommands: activityCommands,
      now: () => now,
    );
  });

  test('incognito beginReadSession is no-op', () async {
    await coordinator.beginReadSession(
      comic: _comic(),
      incognito: true,
      initialPageIndex: 3,
    );

    expect(readingCommands.records, isEmpty);
    expect(activityCommands.records, isEmpty);
    expect(coordinator.hasActiveSession, isFalse);
  });

  test('beginReadSession writes only comic history', () async {
    await coordinator.beginReadSession(comic: _comic(), initialPageIndex: 2);

    expect(readingCommands.records, hasLength(1));
    expect(readingCommands.records.single.comicId, 'c1');
    expect(readingCommands.records.single.pageIndex, 2);
    expect(coordinator.hasActiveSession, isTrue);
  });

  test('updatePage and flushProgress persist latest page only', () async {
    await coordinator.beginReadSession(comic: _comic(), initialPageIndex: 1);
    readingCommands.records.clear();
    activityCommands.records.clear();

    now = now.add(const Duration(seconds: 5));
    coordinator.updatePage(7);
    await coordinator.flushProgress();

    expect(readingCommands.records, hasLength(1));
    expect(readingCommands.records.single.pageIndex, 7);
    expect(activityCommands.records, isEmpty);
  });

  test('endSession reports foreground elapsed once', () async {
    await coordinator.beginReadSession(comic: _comic(), initialPageIndex: 3);
    readingCommands.records.clear();
    activityCommands.records.clear();

    now = now.add(const Duration(seconds: 45));
    coordinator.updatePage(5);
    await coordinator.endSession();

    expect(readingCommands.records, hasLength(1));
    expect(readingCommands.records.single.pageIndex, 5);
    expect(coordinator.hasActiveSession, isFalse);
    expect(activityCommands.records, hasLength(1));
    expect(activityCommands.records.single.comicId, 'c1');
    expect(activityCommands.records.single.pageIndex, 5);
    expect(activityCommands.records.single.pageCount, 10);
    expect(
      activityCommands.records.single.foregroundElapsed,
      const Duration(seconds: 45),
    );
  });

  test(
    'pauseForeground reports then resume continues without double count',
    () async {
      await coordinator.beginReadSession(comic: _comic(), initialPageIndex: 1);
      activityCommands.records.clear();

      now = now.add(const Duration(seconds: 20));
      await coordinator.pauseForeground();
      expect(activityCommands.records, hasLength(1));
      expect(
        activityCommands.records.single.foregroundElapsed,
        const Duration(seconds: 20),
      );

      now = now.add(const Duration(seconds: 30));
      coordinator.resumeForeground();
      now = now.add(const Duration(seconds: 15));
      await coordinator.endSession();

      expect(activityCommands.records, hasLength(2));
      expect(
        activityCommands.records.last.foregroundElapsed,
        const Duration(seconds: 15),
      );
    },
  );

  test(
    'exitReadSession flushes history, reports activity, closes I/O',
    () async {
      await coordinator.beginReadSession(comic: _comic(), initialPageIndex: 2);
      readingCommands.records.clear();
      activityCommands.records.clear();

      now = now.add(const Duration(seconds: 12));
      coordinator.updatePage(6);
      await coordinator.exitReadSession(
        comicId: 'c1',
        incognito: false,
        currentPageIndex: 6,
      );

      expect(readingCommands.records, hasLength(1));
      expect(readingCommands.records.single.pageIndex, 6);
      expect(activityCommands.records, hasLength(1));
      expect(
        activityCommands.records.single.foregroundElapsed,
        const Duration(seconds: 12),
      );
      expect(coordinator.hasActiveSession, isFalse);
      expect(sessionService.closedComicIds, <String>['c1']);
    },
  );

  test('exitReadSession skips history and activity when incognito', () async {
    await coordinator.exitReadSession(
      comicId: 'c1',
      incognito: true,
      currentPageIndex: 3,
    );

    expect(readingCommands.records, isEmpty);
    expect(activityCommands.records, isEmpty);
    expect(sessionService.closedComicIds, <String>['c1']);
  });

  test(
    'prepareSeriesSwitch returns next session starting from first page',
    () async {
      await coordinator.beginReadSession(comic: _comic(), initialPageIndex: 3);
      readingCommands.records.clear();
      activityCommands.records.clear();

      now = now.add(const Duration(seconds: 11));
      final SeriesSwitchPlan plan = await coordinator.prepareSeriesSwitch(
        currentSession: const OpenReaderArgs(comicId: 'c1'),
        targetComicId: 'c2',
        currentPageIndex: 8,
      );

      expect(readingCommands.records, hasLength(1));
      expect(readingCommands.records.single.pageIndex, 8);
      expect(activityCommands.records, hasLength(1));
      expect(
        activityCommands.records.single.foregroundElapsed,
        const Duration(seconds: 11),
      );
      expect(coordinator.hasActiveSession, isFalse);
      expect(sessionService.closedComicIds, <String>['c1']);
      expect(plan.closeComicId, 'c1');
      expect(plan.targetComicId, 'c2');
      expect(plan.nextSession.comicId, 'c2');
      expect(plan.nextSession.startFromFirstPage, isTrue);
    },
  );
}
