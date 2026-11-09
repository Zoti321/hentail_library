import 'package:hentai_library/shared/domain/models/entity/comic/comic.dart';
import 'package:hentai_library/features/read_session/domain/read_session.dart';
import 'package:hentai_library/features/read_session/application/reader_session_service.dart';
import 'package:hentai_library/shared/domain/ports/reading_history_command_port.dart';
import 'package:hentai_library/shared/domain/ports/record_read_session_activity_port.dart';

class _ActiveReadingSession {
  _ActiveReadingSession({
    required this.comic,
    required this.pageIndex,
    required DateTime foregroundStartedAt,
  }) : _foregroundStartedAt = foregroundStartedAt;

  final Comic comic;
  int pageIndex;
  DateTime? _foregroundStartedAt;
  Duration _accruedForeground = Duration.zero;

  void pauseForeground(DateTime now) {
    final DateTime? started = _foregroundStartedAt;
    if (started == null) {
      return;
    }
    _accruedForeground += now.difference(started);
    _foregroundStartedAt = null;
  }

  void resumeForeground(DateTime now) {
    _foregroundStartedAt ??= now;
  }

  /// 取出并清零当前前台累计时长（含进行中的前台段）。
  Duration takeForegroundElapsed(DateTime now) {
    pauseForeground(now);
    final Duration elapsed = _accruedForeground;
    _accruedForeground = Duration.zero;
    return elapsed;
  }
}

/// 系列切卷时 coordinator 返回的计划；UI 负责 prefetch 与路由跳转。
typedef SeriesSwitchPlan = ({
  String closeComicId,
  String targetComicId,
  ReadSessionRouteParams nextSession,
});

/// 窄协调：open → 翻页进度 → 写历史 / 活动统计 → close / 系列切卷。
class ReadSessionCoordinator {
  ReadSessionCoordinator({
    required this.sessionService,
    required this.readingHistoryCommands,
    required this.activityCommands,
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  final ReaderSessionService sessionService;
  final ReadingHistoryCommandPort readingHistoryCommands;
  final RecordReadSessionActivityPort activityCommands;
  final DateTime Function() _now;

  _ActiveReadingSession? _session;
  Future<void>? _flushInFlight;

  bool get hasActiveSession => _session != null;

  Future<void> beginReadSession({
    required Comic comic,
    bool incognito = false,
    int initialPageIndex = 1,
  }) async {
    if (incognito) {
      _session = null;
      return;
    }
    if (_session != null && _session!.comic.comicId != comic.comicId) {
      await _flushSession(_session!);
      await _reportActivity(_session!);
    }
    _session = _ActiveReadingSession(
      comic: comic,
      pageIndex: initialPageIndex.clamp(1, 1 << 30),
      foregroundStartedAt: _now(),
    );
    await _flushSession(_session!);
  }

  void updatePage(int pageIndex) {
    if (_session == null || pageIndex < 1) {
      return;
    }
    _session!.pageIndex = pageIndex;
  }

  /// App 进入后台：停表并上报活动事实（时长只结算本段）。
  Future<void> pauseForeground() async {
    final _ActiveReadingSession? session = _session;
    if (session == null) {
      return;
    }
    session.pauseForeground(_now());
    await _reportActivity(session);
  }

  /// App 回到前台：重新开表。
  void resumeForeground() {
    _session?.resumeForeground(_now());
  }

  Future<void> flushProgress() async {
    final _ActiveReadingSession? session = _session;
    if (session == null) {
      return;
    }
    await _flushSession(session);
  }

  Future<void> endSession() async {
    final _ActiveReadingSession? session = _session;
    if (session == null) {
      return;
    }
    _session = null;
    await _flushSession(session);
    await _reportActivity(session);
  }

  Future<void> exitReadSession({
    required String comicId,
    required bool incognito,
    int? currentPageIndex,
  }) async {
    if (!incognito) {
      if (currentPageIndex != null) {
        updatePage(currentPageIndex);
      }
      await endSession();
    }
    await sessionService.close(comicId);
  }

  Future<SeriesSwitchPlan> prepareSeriesSwitch({
    required ReadSessionRouteParams currentSession,
    required String targetComicId,
    int? currentPageIndex,
  }) async {
    if (targetComicId == currentSession.comicId) {
      throw ArgumentError.value(
        targetComicId,
        'targetComicId',
        'must differ from current comic',
      );
    }
    if (!currentSession.incognito) {
      if (currentPageIndex != null) {
        updatePage(currentPageIndex);
      }
      await endSession();
    }
    await sessionService.close(currentSession.comicId);
    return (
      closeComicId: currentSession.comicId,
      targetComicId: targetComicId,
      nextSession: ReadSessionRouteParams(
        comicId: targetComicId,
        incognito: currentSession.incognito,
        startFromFirstPage: true,
      ),
    );
  }

  Future<void> _flushSession(_ActiveReadingSession session) async {
    final Future<void>? inFlight = _flushInFlight;
    if (inFlight != null) {
      await inFlight;
    }
    final Future<void> flushTask = _persistSession(session);
    _flushInFlight = flushTask;
    try {
      await flushTask;
    } finally {
      if (identical(_flushInFlight, flushTask)) {
        _flushInFlight = null;
      }
    }
  }

  Future<void> _persistSession(_ActiveReadingSession session) async {
    final DateTime now = _now();
    await readingHistoryCommands.recordReading(
      comicId: session.comic.comicId,
      title: session.comic.title,
      lastReadTime: now,
      pageIndex: session.pageIndex,
    );
  }

  Future<void> _reportActivity(_ActiveReadingSession session) async {
    final Duration elapsed = session.takeForegroundElapsed(_now());
    await activityCommands.record(
      comicId: session.comic.comicId,
      incognito: false,
      foregroundElapsed: elapsed,
      pageIndex: session.pageIndex,
      pageCount: session.comic.pageCount,
    );
  }
}
