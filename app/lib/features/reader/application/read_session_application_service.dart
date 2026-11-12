import 'package:hentai_library/features/reader/domain/reader_comic_ref.dart';
import 'package:hentai_library/features/reader/application/open_reader_args.dart';
import 'package:hentai_library/features/reader/application/open_read_session_service.dart';
import 'package:hentai_library/features/reader/domain/read_session.dart';
import 'package:hentai_library/features/reading_history/public.dart';
import 'package:hentai_library/features/reading_stats/public.dart';

/// 系列切卷时 Application Service 返回的计划；UI 负责 prefetch 与路由跳转。
typedef SeriesSwitchPlan = ({
  String closeComicId,
  String targetComicId,
  OpenReaderArgs nextSession,
});

/// Read session 应用服务：进度落盘 / 活动统计 / close / 系列切卷编排。
class ReadSessionApplicationService {
  ReadSessionApplicationService({
    required this.sessionService,
    required this.recordProgress,
    required this.recordActivity,
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  final OpenReadSessionService sessionService;
  final RecordReadingProgressCommand recordProgress;
  final RecordReadSessionActivityCommand recordActivity;
  final DateTime Function() _now;

  ReadSession? _session;
  Future<void>? _flushInFlight;

  bool get hasActiveSession => _session != null;

  Future<void> beginReadSession({
    required ReaderComicRef comic,
    bool incognito = false,
    int initialPageIndex = 1,
  }) async {
    if (incognito) {
      _session = null;
      return;
    }
    if (_session != null && _session!.comicId != comic.comicId) {
      await _flushSession(_session!);
      await _reportActivity(_session!);
    }
    _session = ReadSession(
      comic: comic,
      initialPageIndex: initialPageIndex,
      foregroundStartedAt: _now(),
    );
    await _flushSession(_session!);
  }

  void updatePage(int pageIndex) {
    final ReadSession? session = _session;
    if (session == null || pageIndex < 1) {
      return;
    }
    session.updatePage(pageIndex);
  }

  /// App 进入后台：停表并上报活动事实（时长只结算本段）。
  Future<void> pauseForeground() async {
    final ReadSession? session = _session;
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
    final ReadSession? session = _session;
    if (session == null) {
      return;
    }
    await _flushSession(session);
  }

  Future<void> endSession() async {
    final ReadSession? session = _session;
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
    required OpenReaderArgs currentSession,
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
      nextSession: OpenReaderArgs(
        comicId: targetComicId,
        incognito: currentSession.incognito,
        startFromFirstPage: true,
      ),
    );
  }

  Future<void> _flushSession(ReadSession session) async {
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

  Future<void> _persistSession(ReadSession session) async {
    final DateTime now = _now();
    await recordProgress(
      comicId: session.comicId,
      title: session.comic.title,
      lastReadTime: now,
      pageIndex: session.pageIndex,
    );
  }

  Future<void> _reportActivity(ReadSession session) async {
    final Duration elapsed = session.takeForegroundElapsed(_now());
    await recordActivity(
      comicId: session.comicId,
      incognito: false,
      foregroundElapsed: elapsed,
      pageIndex: session.pageIndex,
      pageCount: session.comic.pageCount,
    );
  }
}
