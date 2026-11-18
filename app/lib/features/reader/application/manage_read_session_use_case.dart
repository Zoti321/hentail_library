import 'package:hentai_library/features/reader/application/open_reader_args.dart';
import 'package:hentai_library/features/reader/application/open_read_session_use_case.dart';
import 'package:hentai_library/features/reader/application/read_session_page_load_exception.dart';
import 'package:hentai_library/features/reader/domain/image_set_navigation.dart';
import 'package:hentai_library/features/reader/domain/read_session.dart';
import 'package:hentai_library/features/reader/domain/read_session_capabilities.dart';
import 'package:hentai_library/features/reader/domain/read_session_source.dart';
import 'package:hentai_library/features/reader/domain/reader_comic_ref.dart';
import 'package:hentai_library/features/reading_history/public/reading_progress_commands.dart';
import 'package:hentai_library/features/reading_stats/public/read_session_activity.dart';

/// 系列切卷时 UseCase 返回的计划；UI 负责 prefetch 与路由跳转。
typedef SeriesSwitchPlan = ({
  String closeComicId,
  String targetComicId,
  OpenReaderArgs nextSession,
});

/// 跨图集切换计划：当前会话已关闭，UI 用 [nextSource] 打开新的 Read session。
typedef ImageSetSwitchPlan = ({
  String closeSessionKey,
  ImageSetReadSessionSource nextSource,
});

/// Read session lifecycle：进度落盘 / 活动统计 / close / 系列切卷与跨图集切换编排。
class ManageReadSessionUseCase {
  ManageReadSessionUseCase({
    required this.openReadSession,
    required this.recordProgress,
    required this.recordActivity,
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  final OpenReadSessionUseCase openReadSession;
  final RecordReadingProgressCommand recordProgress;
  final RecordReadSessionActivityCommand recordActivity;
  final DateTime Function() _now;

  ReadSession? _session;
  Future<void>? _flushInFlight;
  int _sessionGeneration = 0;

  bool get hasActiveSession => _session != null;

  Future<void> beginReadSession({
    required ReadSessionCapabilities capabilities,
    ReaderComicRef? comic,
    bool incognito = false,
    int initialPageIndex = 1,
  }) async {
    final int generation = ++_sessionGeneration;
    final ReadSession? previous = _session;
    final bool persist =
        capabilities.persistProgress && !incognito && comic != null;
    if (!persist) {
      _session = null;
      return;
    }
    final ReaderComicRef comicRef = comic;
    if (previous != null && previous.comicId != comicRef.comicId) {
      await _flushSession(previous);
      if (generation != _sessionGeneration) {
        return;
      }
      await _reportActivity(previous);
      if (generation != _sessionGeneration) {
        return;
      }
    }
    final ReadSession session = ReadSession(
      comic: comicRef,
      initialPageIndex: initialPageIndex,
      foregroundStartedAt: _now(),
    );
    _session = session;
    await _flushSession(session);
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
    _sessionGeneration++;
    final ReadSession? session = _session;
    if (session == null) {
      return;
    }
    _session = null;
    await _flushSession(session);
    await _reportActivity(session);
  }

  Future<void> exitReadSession({
    required String sessionKey,
    required ReadSessionCapabilities capabilities,
    required bool incognito,
    int? currentPageIndex,
  }) async {
    if (!incognito && capabilities.persistProgress) {
      if (currentPageIndex != null) {
        updatePage(currentPageIndex);
      }
      await endSession();
    } else {
      _sessionGeneration++;
      _session = null;
    }
    await openReadSession.close(sessionKey);
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
    await openReadSession.close(currentSession.comicId);
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

  /// Image set sessions never persist progress, so switching only checks the
  /// target is still a non-empty set of the same library and closes the current
  /// session.
  Future<ImageSetSwitchPlan> prepareImageSetSwitch({
    required ImageSetReadSessionSource currentSession,
    required String targetImageSetId,
  }) async {
    if (targetImageSetId == currentSession.imageSetId) {
      throw ArgumentError.value(
        targetImageSetId,
        'targetImageSetId',
        'must differ from current image set',
      );
    }
    final ImageSetNavigation navigation = await openReadSession
        .loadImageSetNavigation(currentSession);
    if (!navigation.contains(targetImageSetId)) {
      throw ReadSessionPageLoadException.imageSetNotFound(targetImageSetId);
    }
    await openReadSession.close(currentSession.sessionKey);
    return (
      closeSessionKey: currentSession.sessionKey,
      nextSource: ImageSetReadSessionSource(
        libraryId: currentSession.libraryId,
        imageSetId: targetImageSetId,
        startIndex: 0,
      ),
    );
  }

  Future<void> _flushSession(ReadSession session) {
    final Future<void>? inFlight = _flushInFlight;
    final Future<void> flushTask = Future<void>.microtask(() async {
      if (inFlight != null) {
        try {
          await inFlight;
        } catch (_) {
          // The predecessor reports its error to its own caller.
        }
      }
      await _persistSession(session);
    });
    _flushInFlight = flushTask;
    return flushTask.whenComplete(() {
      if (identical(_flushInFlight, flushTask)) {
        _flushInFlight = null;
      }
    });
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
