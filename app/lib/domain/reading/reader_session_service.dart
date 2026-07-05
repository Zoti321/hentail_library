import 'dart:typed_data';

import 'package:hentai_library/domain/models/entity/comic/comic.dart';
import 'package:hentai_library/domain/ports/comic_page_source_port.dart';
import 'package:hentai_library/domain/ports/reader_session_port.dart';
import 'package:hentai_library/domain/repositories/comic_repository.dart';
import 'package:hentai_library/domain/repositories/reading_history_repository.dart';
import 'package:hentai_library/domain/reading/read_session_exceptions.dart';
import 'package:hentai_library/domain/reading/read_session_page.dart';
import 'package:hentai_library/domain/reading/reader_session_snapshot.dart';

/// 阅读 I/O 编排：显式 open/close、页码约定与 session snapshot。
class ReaderSessionService {
  const ReaderSessionService({
    required ComicRepository comicRepo,
    required ComicPageSourcePort pageSource,
    required ReadingHistoryRepository readingHistoryRepo,
    required ReaderSessionPort sessionPort,
  }) : _comicRepo = comicRepo,
       _pageSource = pageSource,
       _readingHistoryRepo = readingHistoryRepo,
       _sessionPort = sessionPort;

  final ComicRepository _comicRepo;
  final ComicPageSourcePort _pageSource;
  final ReadingHistoryRepository _readingHistoryRepo;
  final ReaderSessionPort _sessionPort;

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

  Future<ReaderSessionSnapshot> open({
    required String comicId,
    bool incognito = false,
  }) async {
    final ({Comic comic, List<ReadSessionPage> pages}) opened =
        await _openPages(comicId);
    final int resumePageIndex = incognito
        ? 1
        : clampOneBasedResumeIndex(
            storedPageIndex: (await _readingHistoryRepo.getByComicId(comicId))
                ?.pageIndex,
            totalPages: opened.pages.length,
          );
    return ReaderSessionSnapshot(
      comic: opened.comic,
      pages: opened.pages,
      resumePageIndex: resumePageIndex,
    );
  }

  Future<List<ReadSessionPage>> loadPages(String comicId) async {
    final ({Comic comic, List<ReadSessionPage> pages}) opened =
        await _openPages(comicId);
    return opened.pages;
  }

  Future<void> close(String comicId) => _sessionPort.closeComic(comicId);

  Future<Uint8List?> loadPageBytes({
    required Comic comic,
    required int archivePageIndex,
  }) {
    return _pageSource.loadPageBytes(
      comic: comic,
      pageIndex: archivePageIndex,
    );
  }

  Future<({Comic comic, List<ReadSessionPage> pages})> _openPages(
    String comicId,
  ) async {
    final Comic? comic = await _comicRepo.findById(comicId);
    if (comic == null) {
      throw ReadSessionPageLoadException.comicNotFound(comicId);
    }
    await _sessionPort.openComic(comic);
    try {
      final List<ReadSessionPage> pages = await _pageSource.loadPages(comic);
      if (pages.isEmpty) {
        throw ReadSessionPageLoadException.emptyPages(
          comicId: comic.comicId,
          path: comic.path,
        );
      }
      return (comic: comic, pages: List<ReadSessionPage>.unmodifiable(pages));
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
}
