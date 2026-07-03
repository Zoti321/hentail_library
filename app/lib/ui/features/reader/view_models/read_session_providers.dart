import 'dart:io';
import 'dart:typed_data';

import 'package:hentai_library/core/logging/log_manager.dart';
import 'package:hentai_library/domain/models/entity/comic/comic.dart';
import 'package:hentai_library/domain/models/entity/reading_history.dart';
import 'package:hentai_library/domain/reading/read_session_exceptions.dart';
import 'package:hentai_library/domain/reading/read_session_loader.dart';
import 'package:hentai_library/domain/reading/read_session_page.dart';
import 'package:hentai_library/src/rust/api/init.dart';
import 'package:hentai_library/ui/core/dto/comic_cover_display_data.dart';
import 'package:hentai_library/ui/features/reader/view_models/read_session_page_data.dart';
import 'package:hentai_library/ui/features/shell/di/deps.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'read_session_providers.g.dart';

@Riverpod(keepAlive: true)
ReadSessionLoader readSessionLoader(Ref ref) =>
    ReadSessionLoader(pageSource: ref.read(comicPageSourcePortProvider));

ReaderPageImageData _mapReadSessionPageToUi(ReadSessionPage page) {
  return switch (page) {
    ReadSessionDirPage(:final String filePath) => ReaderDirPageImageData(
      File(filePath),
    ),
    ReadSessionArchivePage(:final String comicId, :final int pageIndex) =>
      ReaderArchivePageImageData(comicId: comicId, pageIndex: pageIndex),
  };
}

@Riverpod()
Future<List<ReaderPageImageData>> comicImages(
  Ref ref, {
  required String comicId,
  String? chapterId,
}) async {
  final Comic? comic = await ref.read(comicRepoProvider).findById(comicId);
  if (comic == null) {
    throw ReadSessionPageLoadException.comicNotFound(comicId);
  }
  final List<ReadSessionPage> pages = await ref
      .read(readSessionLoaderProvider)
      .loadPages(comic);
  return pages.map(_mapReadSessionPageToUi).toList(growable: false);
}

@Riverpod()
Future<Uint8List?> comicReaderPageBytes(
  Ref ref, {
  required String comicId,
  required int pageIndex,
}) async {
  final Comic? comic = await ref.read(comicRepoProvider).findById(comicId);
  if (comic == null) {
    return null;
  }
  try {
    return await ref
        .read(comicPageSourcePortProvider)
        .loadPageBytes(comic: comic, pageIndex: pageIndex);
  } on HentaiErrorDto catch (error, stackTrace) {
    throw ReadSessionPageLoadException.loadFailed(
      comicId: comicId,
      path: comic.path,
      cause: error,
      stackTrace: stackTrace,
    );
  } on Object catch (error, stackTrace) {
    LogManager.instance.handle(
      error,
      stackTrace,
      '加载漫画页面字节失败: comicId=$comicId pageIndex=$pageIndex',
    );
    return null;
  }
}

@Riverpod()
Future<ReadingHistory?> readingProgress(
  Ref ref, {
  required String comicId,
}) async {
  return ref.watch(readingHistoryRepoProvider).getByComicId(comicId);
}

@Riverpod()
Future<ComicCoverDisplayData?> comicCoverDisplay(
  Ref ref, {
  required String comicId,
}) async {
  final Comic? comic = await ref.read(comicRepoProvider).findById(comicId);
  if (comic == null) {
    return null;
  }
  try {
    final record = await ref
        .read(comicThumbnailRepoProvider)
        .findByComicId(comicId);
    final Uint8List? bytes = record?.thumbnail;
    if (bytes == null || bytes.isEmpty) {
      return null;
    }
    return ComicCoverDisplayData.bytes(bytes);
  } on Object catch (error, stackTrace) {
    LogManager.instance.handle(
      error,
      stackTrace,
      '加载漫画封面失败: comicId=$comicId, path=${comic.path}, type=${comic.resourceType}',
    );
    return null;
  }
}
