import 'dart:async';
import 'dart:typed_data';

import 'package:hentai_library/features/reader/application/read_session_page_load_exception.dart';
import 'package:hentai_library/features/reader/domain/comic_page_source_port.dart';
import 'package:hentai_library/features/reader/domain/image_set_read_port.dart';
import 'package:hentai_library/features/reader/domain/native_reader_port.dart';
import 'package:hentai_library/features/reader/domain/opened_read_session.dart';
import 'package:hentai_library/features/reader/domain/read_session_capabilities.dart';
import 'package:hentai_library/features/reader/domain/read_session_page.dart';
import 'package:hentai_library/features/reader/domain/read_session_source.dart';
import 'package:hentai_library/features/reader/domain/read_session_subject.dart';
import 'package:hentai_library/features/reader/domain/reader_comic_ref.dart';
import 'package:hentai_library/features/reader/domain/reader_page_payload.dart';
import 'package:hentai_library/features/reading_history/public/reading_progress_commands.dart';
import 'package:hentai_library/shared/application/contracts/comic_read_query.dart';
import 'package:hentai_library/shared/domain/models/enums.dart';

typedef _OpenedPages = ({
  ReadSessionSubject subject,
  ReaderComicRef? comic,
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
class OpenReadSessionUseCase {
  OpenReadSessionUseCase({
    required this._comicLookup,
    required this._pageSource,
    required this._readResumePage,
    required this._sessionPort,
    this._imageSetReadPort,
    this._openTimeout = defaultOpenTimeout,
  });

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
    final ReadSessionCapabilities capabilities = ReadSessionCapabilities.from(
      source,
      incognito: incognito,
    );
    final int resumePageIndex = switch (source) {
      ImageSetReadSessionSource() => _imageSetResumeIndex(source, opened.pages),
      ComicReadSessionSource() =>
        (incognito || startFromFirstPage)
            ? 1
            : clampOneBasedResumeIndex(
                storedPageIndex: await _readResumePage(sessionKey),
                totalPages: opened.pages.length,
              ),
    };
    _ensureLifetime(sessionKey, lifetime);
    return OpenedReadSession(
      subject: opened.subject,
      source: opened.source,
      capabilities: capabilities,
      pages: opened.pages,
      resumePageIndex: resumePageIndex,
      comic: opened.comic,
    );
  }

  int _imageSetResumeIndex(
    ImageSetReadSessionSource source,
    List<ReadSessionPage> pages,
  ) {
    final String? imageId = source.imageSetImageId;
    if (imageId == null) {
      return clampOneBasedResumeIndex(
        storedPageIndex: source.startIndex + 1,
        totalPages: pages.length,
      );
    }
    final int index = pages.indexWhere(
      (page) =>
          page is ReadSessionImageSetPage &&
          page.page.imageSetImageId == imageId,
    );
    if (index < 0) {
      throw ReadSessionPageLoadException.imageSetImageNotFound(imageId);
    }
    return index + 1;
  }

  /// Load pages for [source]. Prefer an already-opened snapshot.
  Future<List<ReadSessionPage>> loadPages(ReadSessionSource source) async {
    final String sessionKey = source.sessionKey;
    final Object lifetime = _lifetimes.putIfAbsent(sessionKey, Object.new);
    final _OpenedPages opened = await _openPages(source);
    _ensureLifetime(sessionKey, lifetime);
    return opened.pages;
  }

  /// Comic-only convenience; Image set callers must use [loadPages] with source.
  Future<List<ReadSessionPage>> loadPagesByComicId(String comicId) {
    return loadPages(ComicReadSessionSource(comicId));
  }

  ReadSessionSource? openedSource(String sessionKey) =>
      _openedPages[sessionKey]?.source;

  Future<void> close(String sessionKey) async {
    final _OpenedPages? opened = _openedPages.remove(sessionKey);
    _lifetimes.remove(sessionKey);
    _opening.remove(sessionKey);
    if (opened?.source.isImageSet ?? false) {
      return;
    }
    await _closeNative(sessionKey);
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
        final _ = _operations.remove(comicId);
      }
    });
    _operations[comicId] = barrier;
    return closing;
  }

  Future<Uint8List?> loadPageBytes({
    required String sessionKey,
    required int archivePageIndex,
  }) async {
    final _OpenedPages? opened = _openedPages[sessionKey];
    if (opened != null && opened.source.isImageSet) {
      final ReadSessionPage? page = _pageAt(opened.pages, archivePageIndex);
      if (page is! ReadSessionImageSetPage) {
        return null;
      }
      return _requireImageSetPort().loadPageBytes(page.page);
    }
    return _pageSource.loadPageBytes(
      comicId: sessionKey,
      pageIndex: archivePageIndex,
    );
  }

  /// [archivePageIndex] 为 0-based 归档页索引。
  Future<ReaderPagePayload> loadReaderPage({
    required String sessionKey,
    required int archivePageIndex,
  }) async {
    final _OpenedPages? opened = _openedPages[sessionKey];
    if (opened != null && opened.source.isImageSet) {
      final ReadSessionPage? page = _pageAt(opened.pages, archivePageIndex);
      if (page is! ReadSessionImageSetPage) {
        throw ReadSessionPageLoadException.loadFailed(
          comicId: sessionKey,
          path: opened.subject.sessionKey,
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
            comicId: sessionKey,
            path: opened.subject.sessionKey,
            cause: error,
            stackTrace: stackTrace,
          ),
          stackTrace,
        );
      }
    }
    final ReaderComicRef? comic = await _resolveOpenedComic(sessionKey);
    if (comic == null) {
      throw ReadSessionPageLoadException.comicNotFound(sessionKey);
    }
    try {
      return await _pageSource.loadReaderPage(
        comicId: sessionKey,
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

  /// [archivePageIndexes] 为 0-based；目录漫与 Image set 不走 Comic prefetch。
  Future<void> prefetchPages({
    required String sessionKey,
    required List<int> archivePageIndexes,
    required int generation,
  }) async {
    if (archivePageIndexes.isEmpty) {
      return;
    }
    final _OpenedPages? opened = _openedPages[sessionKey];
    if (opened != null && !opened.source.isComic) {
      return;
    }
    final ReaderComicRef? comic = await _resolveOpenedComic(sessionKey);
    if (comic == null || comic.resourceType == ResourceType.dir) {
      return;
    }
    await _pageSource.prefetchPages(
      comicId: sessionKey,
      pageIndexes: archivePageIndexes,
      generation: generation,
    );
  }

  Future<ReaderComicRef?> _resolveOpenedComic(String sessionKey) async {
    final _OpenedPages? opened = _openedPages[sessionKey];
    if (opened != null) {
      return opened.comic;
    }
    final found = await _comicLookup.findById(sessionKey);
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

  Future<void> clearPageCache({required String sessionKey}) {
    final _OpenedPages? opened = _openedPages[sessionKey];
    if (opened != null && !opened.source.isComic) {
      return Future<void>.value();
    }
    return _pageSource.clearPageCache(comicId: sessionKey);
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
          startIndex: source.imageSetImageId == null ? source.startIndex : 0,
        );
    _ensureLifetime(sessionKey, attempt.lifetime);
    if (opened.pages.isEmpty) {
      throw ReadSessionPageLoadException.emptyPages(
        comicId: sessionKey,
        path: sessionKey,
      );
    }
    final ReadSessionSubject subject = ReadSessionSubject(
      sessionKey: sessionKey,
      title: opened.title,
      pageCount: opened.pages.length,
    );
    final List<ReadSessionPage> pages = List<ReadSessionPage>.unmodifiable(
      opened.pages.map(
        (ImageSetReadPage page) => ReadSessionImageSetPage(page: page),
      ),
    );
    final _OpenedPages result = (
      subject: subject,
      comic: null,
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
        subject: ReadSessionSubject(
          sessionKey: comicId,
          title: comic.title,
          pageCount: pages.length,
        ),
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
    String sessionKey,
    _ReaderOpenAttempt attempt,
  ) async {
    try {
      return await attempt.operation.timeout(_openTimeout);
    } on TimeoutException catch (_, stackTrace) {
      if (identical(_lifetimes[sessionKey], attempt.lifetime)) {
        _lifetimes.remove(sessionKey);
      }
      if (attempt.nativeStarted) {
        unawaited(_waitForOperation(_closeNative(sessionKey)));
      }
      Error.throwWithStackTrace(
        ReadSessionPageLoadException.timedOut(
          comicId: sessionKey,
          path: attempt.path ?? sessionKey,
        ),
        stackTrace,
      );
    } on ReadSessionPageLoadException {
      rethrow;
    } on Object catch (error, stackTrace) {
      Error.throwWithStackTrace(
        ReadSessionPageLoadException.loadFailed(
          comicId: sessionKey,
          path: attempt.path ?? sessionKey,
          cause: error,
          stackTrace: stackTrace,
        ),
        stackTrace,
      );
    } finally {
      if (identical(_opening[sessionKey], attempt)) {
        _opening.remove(sessionKey);
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

  void _ensureLifetime(String sessionKey, Object lifetime) {
    if (!identical(_lifetimes[sessionKey], lifetime)) {
      throw ReadSessionPageLoadException.loadFailed(
        comicId: sessionKey,
        path: sessionKey,
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
