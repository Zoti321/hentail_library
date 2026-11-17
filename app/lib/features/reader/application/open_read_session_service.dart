import 'dart:async';
import 'dart:typed_data';

import 'package:hentai_library/features/reader/application/read_session_page_load_exception.dart';
import 'package:hentai_library/features/reader/domain/comic_page_source_port.dart';
import 'package:hentai_library/features/reader/domain/image_set_read_port.dart';
import 'package:hentai_library/features/reader/domain/native_reader_port.dart';
import 'package:hentai_library/features/reader/domain/opened_read_session.dart';
import 'package:hentai_library/features/reader/domain/read_session_page.dart';
import 'package:hentai_library/features/reader/domain/read_session_source.dart';
import 'package:hentai_library/features/reader/domain/reader_comic_ref.dart';
import 'package:hentai_library/features/reader/domain/reader_page_payload.dart';
import 'package:hentai_library/features/reading_history/public/reading_progress_commands.dart';
import 'package:hentai_library/shared/application/contracts/comic_read_query.dart';
import 'package:hentai_library/shared/domain/models/enums.dart';

typedef _OpenedPages = ({
  ReaderComicRef comic,
  List<ReadSessionPage> pages,
  ReadSessionSource source,
});

class _ReaderOpenAttempt {
  _ReaderOpenAttempt(this.lifetime);
  final Object lifetime;
  String? path;
  bool nativeStarted = false;
  late final Future<_OpenedPages> result;
  late final Future<_OpenedPages> operation;
}

/// 阅读 I/O 编排：显式 open/close、页码约定与 [OpenedReadSession]。
///
/// 同一 sessionKey 在 close 前复用页列表，避免 open 与 loadPages 双次列页。
class OpenReadSessionService {
  OpenReadSessionService({
    required this._comicLookup,
    required this._pageSource,
    required this._readResumePage,
    required this._sessionPort,
    ImageSetReadPort? imageSetReadPort,
    this._openTimeout = defaultOpenTimeout,
  }) : _imageSetReadPort = imageSetReadPort;

  /// Resource access / reader open 的默认有界时限（Local + Remote）。
  static const Duration defaultOpenTimeout = Duration(seconds: 30);

  final ComicReadQuery _comicLookup;
  final ComicPageSourcePort _pageSource;
  final ReadResumePageQuery _readResumePage;
  final NativeReaderPort _sessionPort;
  final ImageSetReadPort? _imageSetReadPort;
  final Duration _openTimeout;
  final Map<String, _OpenedPages> _openedPages = <String, _OpenedPages>{};
  final _lifetimes = <String, Object>{};
  final _opening = <String, _ReaderOpenAttempt>{};
  final _operations = <String, Future<Object?>>{};

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
  }) {
    return openFromSource(
      ComicReadSessionSource(comicId),
      incognito: incognito,
      startFromFirstPage: startFromFirstPage,
    );
  }

  Future<OpenedReadSession> openFromSource(
    ReadSessionSource source, {
    bool incognito = false,
    bool startFromFirstPage = false,
  }) async {
    final String sessionKey = source.sessionKey;
    final Object lifetime = _lifetimes.putIfAbsent(sessionKey, Object.new);
    final _OpenedPages opened = await _openPages(source);
    final int resumePageIndex = switch (source) {
      ImageSetReadSessionSource(:final int startIndex) =>
        clampOneBasedResumeIndex(
          storedPageIndex: startIndex + 1,
          totalPages: opened.pages.length,
        ),
      ComicReadSessionSource() => (incognito || startFromFirstPage)
          ? 1
          : clampOneBasedResumeIndex(
              storedPageIndex: await _readResumePage(sessionKey),
              totalPages: opened.pages.length,
            ),
    };
    _ensureLifetime(sessionKey, lifetime);
    return OpenedReadSession(
      comic: opened.comic,
      pages: opened.pages,
      resumePageIndex: resumePageIndex,
    );
  }

  Future<List<ReadSessionPage>> loadPages(String comicId) async {
    final Object lifetime = _lifetimes.putIfAbsent(comicId, Object.new);
    final _OpenedPages opened = await _openPages(
      ComicReadSessionSource(comicId),
    );
    _ensureLifetime(comicId, lifetime);
    return opened.pages;
  }

  Future<void> close(String comicId) async {
    final _OpenedPages? opened = _openedPages.remove(comicId);
    _lifetimes.remove(comicId);
    _opening.remove(comicId);
    if (opened?.source.isImageSet ?? comicId.startsWith('image_set:')) {
      return;
    }
    await _closeNative(comicId);
  }

  Future<void> _closeNative(String comicId) {
    final previous = _operations[comicId];
    final closing = Future<void>.microtask(
      () => _sessionPort.closeComic(comicId),
    );
    late final Future<void> barrier;
    barrier = Future<void>.microtask(() async {
      await _waitForOperation(previous);
      await _waitForOperation(closing);
      if (identical(_operations[comicId], barrier)) {
        // The operation is already observed; only remove its map entry.
        final _ = _operations.remove(comicId);
      }
    });
    _operations[comicId] = barrier;
    return closing;
  }

  Future<Uint8List?> loadPageBytes({
    required String comicId,
    required int archivePageIndex,
  }) async {
    final _OpenedPages? opened = _openedPages[comicId];
    if (opened != null && opened.source.isImageSet) {
      final ReadSessionPage? page = _pageAt(opened.pages, archivePageIndex);
      if (page is! ReadSessionImageSetPage) {
        return null;
      }
      return _requireImageSetPort().loadPageBytes(page.page);
    }
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
    final _OpenedPages? opened = _openedPages[comicId];
    if (opened != null && opened.source.isImageSet) {
      final ReadSessionPage? page = _pageAt(opened.pages, archivePageIndex);
      if (page is! ReadSessionImageSetPage) {
        throw ReadSessionPageLoadException.loadFailed(
          comicId: comicId,
          path: comic.path,
          cause: StateError('Image set page missing at $archivePageIndex'),
        );
      }
      try {
        final Uint8List bytes = await _requireImageSetPort().loadPageBytes(
          page.page,
        );
        return ReaderPageBytes(bytes);
      } on Object catch (error, stackTrace) {
        Error.throwWithStackTrace(
          ReadSessionPageLoadException.loadFailed(
            comicId: comic.comicId,
            path: comic.path,
            cause: error,
            stackTrace: stackTrace,
          ),
          stackTrace,
        );
      }
    }
    try {
      return await _pageSource.loadReaderPage(
        comicId: comicId,
        pageIndex: archivePageIndex,
      );
    } on ReadSessionPageLoadException {
      rethrow;
    } on Object catch (error, stackTrace) {
      Error.throwWithStackTrace(
        ReadSessionPageLoadException.loadFailed(
          comicId: comic.comicId,
          path: comic.path,
          cause: error,
          stackTrace: stackTrace,
        ),
        stackTrace,
      );
    }
  }

  /// [archivePageIndexes] 为 0-based 归档页索引；目录漫与 Image set 不走 Comic prefetch。
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
    final _OpenedPages? opened = _openedPages[comicId];
    if (opened != null && opened.source.isImageSet) {
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
    final _OpenedPages? opened = _openedPages[comicId];
    if (opened != null) {
      return opened.comic;
    }
    if (comicId.startsWith('image_set:')) {
      return null;
    }
    final found = await _comicLookup.findById(comicId);
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
    if (comicId.startsWith('image_set:') ||
        (_openedPages[comicId]?.source.isImageSet ?? false)) {
      return Future<void>.value();
    }
    return _pageSource.clearPageCache(comicId: comicId);
  }

  Future<_OpenedPages> _openPages(ReadSessionSource source) async {
    final String sessionKey = source.sessionKey;
    final _OpenedPages? cached = _openedPages[sessionKey];
    if (cached != null) {
      return cached;
    }
    final existing = _opening[sessionKey];
    if (existing != null) {
      return existing.result;
    }
    final attempt = _ReaderOpenAttempt(
      _lifetimes.putIfAbsent(sessionKey, Object.new),
    );
    attempt.operation = Future<_OpenedPages>.microtask(
      () => switch (source) {
        ComicReadSessionSource(:final String comicId) => _runOpenComic(
          comicId,
          attempt,
        ),
        ImageSetReadSessionSource() => _runOpenImageSet(source, attempt),
      },
    );
    _opening[sessionKey] = attempt;
    attempt.result = _finishOpen(sessionKey, attempt);
    return attempt.result;
  }

  Future<_OpenedPages> _runOpenComic(
    String comicId,
    _ReaderOpenAttempt attempt,
  ) async {
    _ensureLifetime(comicId, attempt.lifetime);
    final found = await _comicLookup.findById(comicId);
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
    attempt.path = comic.path;
    _ensureLifetime(comicId, attempt.lifetime);
    final previous = _operations[comicId];
    late final Future<_OpenedPages> nativeOperation;
    nativeOperation = Future<_OpenedPages>.microtask(() async {
      await _waitForOperation(previous);
      try {
        _ensureLifetime(comicId, attempt.lifetime);
        return await _openNative(comic, attempt);
      } finally {
        if (identical(_operations[comicId], nativeOperation)) {
          // The operation is already observed; only remove its map entry.
          final _ = _operations.remove(comicId);
        }
      }
    });
    _operations[comicId] = nativeOperation;
    return nativeOperation;
  }

  Future<_OpenedPages> _runOpenImageSet(
    ImageSetReadSessionSource source,
    _ReaderOpenAttempt attempt,
  ) async {
    final String sessionKey = source.sessionKey;
    _ensureLifetime(sessionKey, attempt.lifetime);
    attempt.path = sessionKey;
    final ImageSetOpenedReadSession opened = await _requireImageSetPort()
        .openSession(
          libraryId: source.libraryId,
          imageSetId: source.imageSetId,
          startIndex: source.startIndex,
        );
    _ensureLifetime(sessionKey, attempt.lifetime);
    if (opened.pages.isEmpty) {
      throw ReadSessionPageLoadException.emptyPages(
        comicId: sessionKey,
        path: sessionKey,
      );
    }
    final ReaderComicRef comic = ReaderComicRef(
      comicId: sessionKey,
      path: sessionKey,
      resourceType: ResourceType.dir,
      pageCount: opened.pages.length,
      title: opened.title,
    );
    final List<ReadSessionPage> pages = List<ReadSessionPage>.unmodifiable(
      opened.pages.map(
        (ImageSetReadPage page) => ReadSessionImageSetPage(page: page),
      ),
    );
    final _OpenedPages result = (
      comic: comic,
      pages: pages,
      source: source,
    );
    _openedPages[sessionKey] = result;
    return result;
  }

  Future<_OpenedPages> _openNative(
    ReaderComicRef comic,
    _ReaderOpenAttempt attempt,
  ) async {
    final comicId = comic.comicId;
    try {
      attempt.nativeStarted = true;
      await _sessionPort.openComic(comic);
      _ensureLifetime(comicId, attempt.lifetime);
      final pages = await _pageSource.loadPages(comic);
      _ensureLifetime(comicId, attempt.lifetime);
      if (pages.isEmpty) {
        throw ReadSessionPageLoadException.emptyPages(
          comicId: comicId,
          path: comic.path,
        );
      }
      final opened = (
        comic: comic,
        pages: List<ReadSessionPage>.unmodifiable(pages),
        source: ComicReadSessionSource(comicId),
      );
      _openedPages[comicId] = opened;
      return opened;
    } catch (_) {
      await _bestEffortClose(comicId);
      rethrow;
    }
  }

  Future<_OpenedPages> _finishOpen(
    String comicId,
    _ReaderOpenAttempt attempt,
  ) async {
    try {
      return await attempt.operation.timeout(_openTimeout);
    } on TimeoutException catch (_, stackTrace) {
      if (identical(_lifetimes[comicId], attempt.lifetime)) {
        _lifetimes.remove(comicId);
      }
      if (attempt.nativeStarted) {
        // Keep cleanup in the native barrier without delaying the timeout result.
        unawaited(_waitForOperation(_closeNative(comicId)));
      }
      Error.throwWithStackTrace(
        ReadSessionPageLoadException.timedOut(
          comicId: comicId,
          path: attempt.path ?? comicId,
        ),
        stackTrace,
      );
    } on ReadSessionPageLoadException {
      rethrow;
    } on Object catch (error, stackTrace) {
      Error.throwWithStackTrace(
        ReadSessionPageLoadException.loadFailed(
          comicId: comicId,
          path: attempt.path ?? comicId,
          cause: error,
          stackTrace: stackTrace,
        ),
        stackTrace,
      );
    } finally {
      if (identical(_opening[comicId], attempt)) {
        _opening.remove(comicId);
      }
    }
  }

  Future<void> _waitForOperation(Future<Object?>? operation) async {
    try {
      await operation;
    } catch (_) {
      // Each operation reports its own failure to its caller.
    }
  }

  void _ensureLifetime(String comicId, Object lifetime) {
    if (!identical(_lifetimes[comicId], lifetime)) {
      throw ReadSessionPageLoadException.loadFailed(
        comicId: comicId,
        path: comicId,
        cause: StateError('Reader open was closed'),
      );
    }
  }

  Future<void> _bestEffortClose(String comicId) async {
    _openedPages.remove(comicId);
    try {
      await _sessionPort.closeComic(comicId);
    } on Object {
      // Open failure cleanup must not mask the original error.
    }
  }

  ImageSetReadPort _requireImageSetPort() {
    final ImageSetReadPort? port = _imageSetReadPort;
    if (port == null) {
      throw StateError('ImageSetReadPort is not bound');
    }
    return port;
  }

  ReadSessionPage? _pageAt(List<ReadSessionPage> pages, int index) {
    if (index < 0 || index >= pages.length) {
      return null;
    }
    return pages[index];
  }
}
