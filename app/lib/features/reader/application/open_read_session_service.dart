import 'dart:async';
import 'dart:typed_data';

import 'package:hentai_library/features/reader/domain/reader_comic_ref.dart';
import 'package:hentai_library/shared/domain/models/enums.dart';
import 'package:hentai_library/features/reader/domain/comic_page_source_port.dart';
import 'package:hentai_library/features/reader/domain/native_reader_port.dart';
import 'package:hentai_library/features/comic/public/comic_lookup_repository.dart';
import 'package:hentai_library/shared/domain/ports/reading_history_command_port.dart';
import 'package:hentai_library/features/reader/application/read_session_page_load_exception.dart';
import 'package:hentai_library/features/reader/domain/read_session_page.dart';
import 'package:hentai_library/features/reader/domain/reader_page_payload.dart';
import 'package:hentai_library/features/reader/domain/opened_read_session.dart';

/// 阅读 I/O 编排：显式 open/close、页码约定与 [OpenedReadSession]。
///
/// 同一 comicId 在 close 前复用页列表，避免 open 与 loadPages 双次列页。
class OpenReadSessionService {
  OpenReadSessionService({
    required this._comicRepo,
    required this._pageSource,
    required this._readingHistoryCommands,
    required this._sessionPort,
    this._openTimeout = defaultOpenTimeout,
  });

  /// Resource access / reader open 的默认有界时限（Local + Remote）。
  static const Duration defaultOpenTimeout = Duration(seconds: 30);

  final ComicLookupRepository _comicRepo;
  final ComicPageSourcePort _pageSource;
  final ReadingHistoryCommandPort _readingHistoryCommands;
  final NativeReaderPort _sessionPort;
  final Duration _openTimeout;
  final Map<String, ({ReaderComicRef comic, List<ReadSessionPage> pages})>
  _openedPages =
      <String, ({ReaderComicRef comic, List<ReadSessionPage> pages})>{};

  /// UI 页码为 1-based；归档页字节 API 为 0-based。
  static int uiToArchivePageIndex(int oneBasedPageIndex) =>
      oneBasedPageIndex - 1;

  static int clampOneBasedResumeIndex({
    required int? storedPageIndex,
    required int totalPages,
  }) {
    final int fallback = storedPageIndex ?? 1;
    if (totalPages <= 0) {
      return fallback.clamp(1, 1);
    }
    return fallback.clamp(1, totalPages);
  }

  Future<OpenedReadSession> open({
    required String comicId,
    bool incognito = false,
    bool startFromFirstPage = false,
  }) async {
    final ({ReaderComicRef comic, List<ReadSessionPage> pages}) opened =
        await _openPages(comicId);
    final int resumePageIndex = (incognito || startFromFirstPage)
        ? 1
        : clampOneBasedResumeIndex(
            storedPageIndex: await _readingHistoryCommands.readResumePageIndex(
              comicId,
            ),
            totalPages: opened.pages.length,
          );
    return OpenedReadSession(
      comic: opened.comic,
      pages: opened.pages,
      resumePageIndex: resumePageIndex,
    );
  }

  Future<List<ReadSessionPage>> loadPages(String comicId) async {
    final ({ReaderComicRef comic, List<ReadSessionPage> pages}) opened =
        await _openPages(comicId);
    return opened.pages;
  }

  Future<void> close(String comicId) async {
    _openedPages.remove(comicId);
    await _sessionPort.closeComic(comicId);
  }

  Future<Uint8List?> loadPageBytes({
    required String comicId,
    required int archivePageIndex,
  }) {
    return _pageSource.loadPageBytes(
      comicId: comicId,
      pageIndex: archivePageIndex,
    );
  }

  /// [archivePageIndex] 为 0-based 归档页索引。
  Future<ReaderPagePayload> loadReaderPage({
    required String comicId,
    required int archivePageIndex,
  }) async {
    final ReaderComicRef? comic = await _resolveOpenedComic(comicId);
    if (comic == null) {
      throw ReadSessionPageLoadException.comicNotFound(comicId);
    }
    try {
      return await _pageSource.loadReaderPage(
        comicId: comicId,
        pageIndex: archivePageIndex,
      );
    } on ReadSessionPageLoadException {
      rethrow;
    } on Object catch (error, stackTrace) {
      throw ReadSessionPageLoadException.loadFailed(
        comicId: comic.comicId,
        path: comic.path,
        cause: error,
        stackTrace: stackTrace,
      );
    }
  }

  /// [archivePageIndexes] 为 0-based 归档页索引；目录漫不预取。
  Future<void> prefetchPages({
    required String comicId,
    required List<int> archivePageIndexes,
    required int generation,
  }) async {
    if (archivePageIndexes.isEmpty) {
      return;
    }
    final ReaderComicRef? comic = await _resolveOpenedComic(comicId);
    if (comic == null || comic.resourceType == ResourceType.dir) {
      return;
    }
    await _pageSource.prefetchPages(
      comicId: comicId,
      pageIndexes: archivePageIndexes,
      generation: generation,
    );
  }

  /// Prefer in-session comic to avoid a findById FRB on every page load/prefetch.
  Future<ReaderComicRef?> _resolveOpenedComic(String comicId) async {
    final ({ReaderComicRef comic, List<ReadSessionPage> pages})? opened =
        _openedPages[comicId];
    if (opened != null) {
      return opened.comic;
    }
    final found = await _comicRepo.findById(comicId);
    return found == null
        ? null
        : ReaderComicRef(
            comicId: found.comicId,
            path: found.path,
            resourceType: found.resourceType,
            pageCount: found.pageCount,
            title: found.title,
          );
  }

  Future<void> clearPageCache({required String comicId}) {
    return _pageSource.clearPageCache(comicId: comicId);
  }

  Future<({ReaderComicRef comic, List<ReadSessionPage> pages})> _openPages(
    String comicId,
  ) async {
    final ({ReaderComicRef comic, List<ReadSessionPage> pages})? cached =
        _openedPages[comicId];
    if (cached != null) {
      return cached;
    }
    final found = await _comicRepo.findById(comicId);
    if (found == null) {
      throw ReadSessionPageLoadException.comicNotFound(comicId);
    }
    final ReaderComicRef comic = ReaderComicRef(
      comicId: found.comicId,
      path: found.path,
      resourceType: found.resourceType,
      pageCount: found.pageCount,
      title: found.title,
    );
    try {
      final ({ReaderComicRef comic, List<ReadSessionPage> pages}) opened =
          await _openPagesUncached(comic).timeout(_openTimeout);
      _openedPages[comicId] = opened;
      return opened;
    } on TimeoutException {
      await _bestEffortClose(comic.comicId);
      throw ReadSessionPageLoadException.timedOut(
        comicId: comic.comicId,
        path: comic.path,
      );
    } on ReadSessionPageLoadException {
      await _bestEffortClose(comic.comicId);
      rethrow;
    } on Object catch (error, stackTrace) {
      await _bestEffortClose(comic.comicId);
      throw ReadSessionPageLoadException.loadFailed(
        comicId: comic.comicId,
        path: comic.path,
        cause: error,
        stackTrace: stackTrace,
      );
    }
  }

  Future<({ReaderComicRef comic, List<ReadSessionPage> pages})>
  _openPagesUncached(ReaderComicRef comic) async {
    await _sessionPort.openComic(comic);
    final List<ReadSessionPage> pages = await _pageSource.loadPages(comic);
    if (pages.isEmpty) {
      throw ReadSessionPageLoadException.emptyPages(
        comicId: comic.comicId,
        path: comic.path,
      );
    }
    return (comic: comic, pages: List<ReadSessionPage>.unmodifiable(pages));
  }

  Future<void> _bestEffortClose(String comicId) async {
    _openedPages.remove(comicId);
    try {
      await _sessionPort.closeComic(comicId);
    } on Object {
      // Open failure cleanup must not mask the original error.
    }
  }
}
