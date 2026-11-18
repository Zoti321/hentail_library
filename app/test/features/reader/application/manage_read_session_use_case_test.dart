import 'dart:async';

import 'package:hentai_library/features/reader/domain/reader_comic_ref.dart';
import 'package:hentai_library/features/reader/domain/read_session_capabilities.dart';
import 'package:hentai_library/features/reader/domain/read_session_source.dart';
import 'package:hentai_library/shared/domain/models/enums.dart';
import 'package:hentai_library/features/reader/application/open_reader_args.dart';
import 'package:hentai_library/features/reader/application/manage_read_session_use_case.dart';
import 'package:hentai_library/features/reader/application/open_read_session_use_case.dart';
import 'package:test/test.dart';

class _RecordingReadingHistoryCommands {
  final List<
    ({String comicId, String title, int pageIndex, DateTime lastReadTime})
  >
  records = [];
  final pendingWrites = <int, Completer<void>>{};
  final startedWrites = <int, Completer<void>>{};
  final persistedPages = <String, int>{};
  void Function(int)? onWriteStarted;

  Future<void> recordReading({
    required String comicId,
    required String title,
    required DateTime lastReadTime,
    required int pageIndex,
  }) async {
    records.add((
      comicId: comicId,
      title: title,
      pageIndex: pageIndex,
      lastReadTime: lastReadTime,
    ));
    final callIndex = records.length;
    startedWrites[callIndex]?.complete();
    onWriteStarted?.call(callIndex);
    if (pendingWrites[callIndex] case final pending?) await pending.future;
    persistedPages[comicId] = pageIndex;
  }

  Future<int?> readResumePageIndex(String comicId) async => null;
}

class _RecordingActivityCommands {
  final pendingReports = <int, Completer<void>>{};
  final startedReports = <int, Completer<void>>{};
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
    final callIndex = records.length;
    startedReports[callIndex]?.complete();
    if (pendingReports[callIndex] case final pending?) await pending.future;
  }
}

class _RecordingOpenReadSessionUseCase implements OpenReadSessionUseCase {
  _RecordingOpenReadSessionUseCase() : closedComicIds = <String>[];

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

ReadSessionCapabilities _comicCaps({bool incognito = false}) =>
    ReadSessionCapabilities.from(
      ComicReadSessionSource('c1'),
      incognito: incognito,
    );

void main() {
  late _RecordingReadingHistoryCommands readingCommands;
  late _RecordingActivityCommands activityCommands;
  late _RecordingOpenReadSessionUseCase openReadSession;
  late ManageReadSessionUseCase coordinator;
  late DateTime now;

  setUp(() {
    readingCommands = _RecordingReadingHistoryCommands();
    activityCommands = _RecordingActivityCommands();
    openReadSession = _RecordingOpenReadSessionUseCase();
    now = DateTime.utc(2026, 1, 1, 12);
    coordinator = ManageReadSessionUseCase(
      openReadSession: openReadSession,
      recordProgress: readingCommands.recordReading,
      recordActivity: activityCommands.record,
      now: () => now,
    );
  });

  test('incognito beginReadSession is no-op', () async {
    await coordinator.beginReadSession(
      capabilities: _comicCaps(),
      
      comic: _comic(),
      incognito: true,
      initialPageIndex: 3,
    );

    expect(readingCommands.records, isEmpty);
    expect(activityCommands.records, isEmpty);
    expect(coordinator.hasActiveSession, isFalse);
  });

  test('beginReadSession writes only comic history', () async {
    await coordinator.beginReadSession(
      capabilities: _comicCaps(),
      comic: _comic(), initialPageIndex: 2);

    expect(readingCommands.records, hasLength(1));
    expect(readingCommands.records.single.comicId, 'c1');
    expect(readingCommands.records.single.pageIndex, 2);
    expect(coordinator.hasActiveSession, isTrue);
  });

  test('updatePage and flushProgress persist latest page only', () async {
    await coordinator.beginReadSession(
      capabilities: _comicCaps(),
      comic: _comic(), initialPageIndex: 1);
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
    await coordinator.beginReadSession(
      capabilities: _comicCaps(),
      comic: _comic(), initialPageIndex: 3);
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
      await coordinator.beginReadSession(
      capabilities: _comicCaps(),
      comic: _comic(), initialPageIndex: 1);
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
      await coordinator.beginReadSession(
      capabilities: _comicCaps(),
      comic: _comic(), initialPageIndex: 2);
      readingCommands.records.clear();
      activityCommands.records.clear();

      now = now.add(const Duration(seconds: 12));
      coordinator.updatePage(6);
      await coordinator.exitReadSession(
        capabilities: _comicCaps(),
      sessionKey: 'c1',
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
      expect(openReadSession.closedComicIds, <String>['c1']);
    },
  );

  test('exitReadSession skips history and activity when incognito', () async {
    await coordinator.exitReadSession(
      capabilities: _comicCaps(),
      sessionKey: 'c1',
      incognito: true,
      currentPageIndex: 3,
    );

    expect(readingCommands.records, isEmpty);
    expect(activityCommands.records, isEmpty);
    expect(openReadSession.closedComicIds, <String>['c1']);
  });

  test(
    'prepareSeriesSwitch returns next session starting from first page',
    () async {
      await coordinator.beginReadSession(
      capabilities: _comicCaps(),
      comic: _comic(), initialPageIndex: 3);
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
      expect(openReadSession.closedComicIds, <String>['c1']);
      expect(plan.closeComicId, 'c1');
      expect(plan.targetComicId, 'c2');
      expect(plan.nextSession.comicId, 'c2');
      expect(plan.nextSession.startFromFirstPage, isTrue);
    },
  );

  test(
    'overlapping begin exit and reopen persist progress in FIFO order',
    () async {
      final initialWrite = Completer<void>();
      final exitWrite = Completer<void>();
      final reopenWrite = Completer<void>();
      final initialStarted = Completer<void>();
      final exitStarted = Completer<void>();
      final reopenStarted = Completer<void>();
      readingCommands.startedWrites.addAll({
        1: initialStarted,
        2: exitStarted,
        3: reopenStarted,
      });
      readingCommands.pendingWrites.addAll({
        1: initialWrite,
        2: exitWrite,
        3: reopenWrite,
      });

      final initial = coordinator.beginReadSession(
      capabilities: _comicCaps(),
      
        comic: _comic(),
        initialPageIndex: 1,
      );
      await initialStarted.future;
      now = now.add(const Duration(seconds: 12));
      final exiting = coordinator.exitReadSession(
        capabilities: _comicCaps(),
      sessionKey: 'c1',
        incognito: false,
        currentPageIndex: 2,
      );
      final reopening = coordinator.beginReadSession(
      capabilities: _comicCaps(),
      
        comic: _comic(),
        initialPageIndex: 7,
      );
      expect(readingCommands.records.map((record) => record.pageIndex), [1]);

      initialWrite.complete();
      await initial;
      await exitStarted.future;
      await Future<void>.delayed(Duration.zero);
      expect(readingCommands.records.map((record) => record.pageIndex), [1, 2]);
      exitWrite.complete();
      await exiting;
      await reopenStarted.future;
      expect(readingCommands.records.map((record) => record.pageIndex), [
        1,
        2,
        7,
      ]);
      reopenWrite.complete();
      await reopening;

      expect(readingCommands.persistedPages['c1'], 7);
      expect(coordinator.hasActiveSession, isTrue);
      expect(activityCommands.records, hasLength(1));
      expect(activityCommands.records.single.comicId, 'c1');
      expect(activityCommands.records.single.pageIndex, 2);
      expect(
        activityCommands.records.single.foregroundElapsed,
        const Duration(seconds: 12),
      );
      expect(openReadSession.closedComicIds, ['c1']);
    },
  );

  test(
    'an incognito begin supersedes an older begin awaiting its previous flush',
    () async {
      await coordinator.beginReadSession(
      capabilities: _comicCaps(),
      comic: _comic());
      final oldFlush = Completer<void>();
      final oldFlushStarted = Completer<void>();
      readingCommands.pendingWrites[2] = oldFlush;
      readingCommands.startedWrites[2] = oldFlushStarted;
      final older = coordinator.beginReadSession(
      capabilities: _comicCaps(),
      comic: _comic(id: 'c2'));
      await oldFlushStarted.future;

      await coordinator.beginReadSession(
      capabilities: _comicCaps(),
      
        comic: _comic(id: 'private'),
        incognito: true,
      );
      expect(coordinator.hasActiveSession, isFalse);
      final settled = expectLater(older, completes);
      oldFlush.complete();
      await settled;

      expect(coordinator.hasActiveSession, isFalse);
      expect(readingCommands.records.map((record) => record.comicId), [
        'c1',
        'c1',
      ]);
      expect(activityCommands.records, isEmpty);
    },
  );

  test('failed progress writes report their own errors without poisoning queued requests', () async {
    final firstWrite = Completer<void>();
    final secondWrite = Completer<void>();
    final firstStarted = Completer<void>();
    final secondStarted = Completer<void>();
    final thirdStarted = Completer<void>();
    readingCommands.pendingWrites.addAll({1: firstWrite, 2: secondWrite});
    readingCommands.startedWrites.addAll({
      1: firstStarted,
      2: secondStarted,
      3: thirdStarted,
    });
    final firstFailure = StateError('initial write failed');
    final secondFailure = StateError('exit write failed');

    final initial = coordinator.beginReadSession(
      capabilities: _comicCaps(),
      
      comic: _comic(),
      initialPageIndex: 1,
    );
    final initialResult = expectLater(initial, throwsA(same(firstFailure)));
    await firstStarted.future;
    final exiting = coordinator.exitReadSession(
      capabilities: _comicCaps(),
      sessionKey: 'c1',
      incognito: false,
      currentPageIndex: 2,
    );
    final exitResult = expectLater(exiting, throwsA(same(secondFailure)));
    final reopening = coordinator.beginReadSession(
      capabilities: _comicCaps(),
      
      comic: _comic(),
      initialPageIndex: 7,
    );

    firstWrite.completeError(firstFailure);
    await initialResult;
    await secondStarted.future;
    expect(readingCommands.records.map((record) => record.pageIndex), [1, 2]);
    secondWrite.completeError(secondFailure);
    await exitResult;
    await thirdStarted.future;
    await reopening;

    expect(readingCommands.records.map((record) => record.pageIndex), [
      1,
      2,
      7,
    ]);
    expect(readingCommands.persistedPages['c1'], 7);
    expect(activityCommands.records, isEmpty);
    expect(openReadSession.closedComicIds, isEmpty);
  });

  test(
    'queued flush reads the latest page and clock when its write starts',
    () async {
      await coordinator.beginReadSession(
      capabilities: _comicCaps(),
      comic: _comic());
      final blockedWrite = Completer<void>();
      final blockedStarted = Completer<void>();
      final queuedStarted = Completer<void>();
      readingCommands.pendingWrites[2] = blockedWrite;
      readingCommands.startedWrites.addAll({
        2: blockedStarted,
        3: queuedStarted,
      });
      coordinator.updatePage(2);
      final blocking = coordinator.flushProgress();
      await blockedStarted.future;
      now = now.add(const Duration(seconds: 1));
      coordinator.updatePage(3);
      final queued = coordinator.flushProgress();
      now = now.add(const Duration(seconds: 8));
      coordinator.updatePage(8);
      final writeTime = now;

      blockedWrite.complete();
      await blocking;
      await queuedStarted.future;
      await queued;

      expect(readingCommands.records.map((record) => record.pageIndex), [
        1,
        2,
        8,
      ]);
      expect(readingCommands.records.last.lastReadTime, writeTime);
      expect(readingCommands.persistedPages['c1'], 8);
      expect(activityCommands.records, isEmpty);
    },
  );

  test('ending during an older begin activity report does not resurrect that begin', () async {
    await coordinator.beginReadSession(
      capabilities: _comicCaps(),
      comic: _comic());
    now = now.add(const Duration(seconds: 12));
    final oldReport = Completer<void>();
    final reportStarted = Completer<void>();
    activityCommands.pendingReports[1] = oldReport;
    activityCommands.startedReports[1] = reportStarted;
    final older = coordinator.beginReadSession(
      capabilities: _comicCaps(),
      comic: _comic(id: 'c2'));
    await reportStarted.future;

    await coordinator.endSession();
    expect(coordinator.hasActiveSession, isFalse);
    expect(activityCommands.records.map((record) => record.comicId), [
      'c1',
      'c1',
    ]);
    expect(
      activityCommands.records.first.foregroundElapsed,
      const Duration(seconds: 12),
    );
    oldReport.complete();
    await expectLater(older, completes);

    expect(coordinator.hasActiveSession, isFalse);
    expect(readingCommands.records.map((record) => record.comicId), [
      'c1',
      'c1',
      'c1',
    ]);
  });

  test('a newer begin supersedes an older begin waiting to flush the previous session', () async {
    await coordinator.beginReadSession(
      capabilities: _comicCaps(),
      comic: _comic());
    now = now.add(const Duration(seconds: 11));
    final oldFlush = Completer<void>();
    final oldStarted = Completer<void>();
    readingCommands.pendingWrites[2] = oldFlush;
    readingCommands.startedWrites[2] = oldStarted;
    final older = coordinator.beginReadSession(
      capabilities: _comicCaps(),
      comic: _comic(id: 'c2'));
    await oldStarted.future;
    final latest = coordinator.beginReadSession(
      capabilities: _comicCaps(),
      
      comic: _comic(id: 'c3'),
      initialPageIndex: 4,
    );

    oldFlush.complete();
    await older;
    await latest;

    expect(coordinator.hasActiveSession, isTrue);
    expect(readingCommands.records.map((record) => record.comicId), [
      'c1',
      'c1',
      'c1',
      'c3',
    ]);
    expect(activityCommands.records.map((record) => record.comicId), ['c1']);
    expect(
      activityCommands.records.single.foregroundElapsed,
      const Duration(seconds: 11),
    );
    coordinator.updatePage(6);
    await coordinator.flushProgress();
    expect(readingCommands.records.last.comicId, 'c3');
    expect(readingCommands.persistedPages['c3'], 6);
  });

  test('a synchronous progress callback queues its reentrant flush after the current write', () async {
    final firstWrite = Completer<void>();
    final firstStarted = Completer<void>();
    readingCommands.pendingWrites[1] = firstWrite;
    readingCommands.startedWrites[1] = firstStarted;
    late Future<void> reentrant;
    readingCommands.onWriteStarted = (callIndex) {
      if (callIndex == 1) reentrant = coordinator.flushProgress();
    };

    final initial = coordinator.beginReadSession(
      capabilities: _comicCaps(),
      comic: _comic());
    await firstStarted.future;
    await Future<void>.delayed(Duration.zero);
    expect(readingCommands.records, hasLength(1));
    firstWrite.complete();
    await initial;
    await reentrant;

    expect(readingCommands.records.map((record) => record.pageIndex), [1, 1]);
    expect(readingCommands.persistedPages['c1'], 1);
  });
}
