import 'package:hentai_library/domain/models/entity/comic/comic.dart';
import 'package:hentai_library/domain/models/entity/reading_history.dart';
import 'package:hentai_library/domain/reading/read_session.dart';
import 'package:hentai_library/domain/reading/reader_session_service.dart';
import 'package:hentai_library/domain/repositories/reading_history_repository.dart';

class _ActiveReadingSession {
  _ActiveReadingSession({
    required this.comic,
    required this.pageIndex,
  });

  final Comic comic;
  int pageIndex;
}

/// 系列切卷时 coordinator 返回的计划；UI 负责 prefetch 与路由跳转。
typedef SeriesSwitchPlan = ({
  String closeComicId,
  String targetComicId,
  ReadSessionRouteParams nextSession,
});

/// 窄协调：open → 翻页进度 → 写历史 → close / 系列切卷。
class ReadSessionCoordinator {
  ReadSessionCoordinator({
    required ReaderSessionService sessionService,
    required ReadingHistoryRepository readingHistoryRepo,
  }) : _sessionService = sessionService,
       _readingHistoryRepo = readingHistoryRepo;

  final ReaderSessionService _sessionService;
  final ReadingHistoryRepository _readingHistoryRepo;

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
    }
    _session = _ActiveReadingSession(
      comic: comic,
      pageIndex: initialPageIndex.clamp(1, 1 << 30),
    );
    await _flushSession(_session!);
  }

  void updatePage(int pageIndex) {
    if (_session == null || pageIndex < 1) {
      return;
    }
    _session!.pageIndex = pageIndex;
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
    await _sessionService.close(comicId);
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
    await _sessionService.close(currentSession.comicId);
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
    final DateTime now = DateTime.now();
    await _readingHistoryRepo.recordReading(
      ReadingHistory(
        comicId: session.comic.comicId,
        title: session.comic.title,
        lastReadTime: now,
        pageIndex: session.pageIndex,
      ),
    );
  }
}
