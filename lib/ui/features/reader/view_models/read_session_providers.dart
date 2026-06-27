import 'dart:io';
import 'dart:typed_data';

import 'package:hentai_library/core/logging/log_manager.dart';
import 'package:hentai_library/data/services/comic/cache/archive_cover_cache.dart';
import 'package:hentai_library/data/services/comic/read_resource_get/api/read_resource_get_service.dart';
import 'package:hentai_library/data/services/comic/read_resource_get/core/comic_read_resource_accessor.dart';
import 'package:hentai_library/data/services/comic/read_resource_get/core/reader_image.dart';
import 'package:hentai_library/data/services/comic/read_resource_get/isolate/archive_cover_loader.dart';
import 'package:hentai_library/domain/models/entity/comic/comic.dart';
import 'package:hentai_library/domain/models/entity/reading_history.dart';
import 'package:hentai_library/domain/models/enums.dart';
import 'package:hentai_library/domain/reading/read_session_exceptions.dart';
import 'package:hentai_library/domain/reading/read_session_loader.dart';
import 'package:hentai_library/domain/reading/read_session_page.dart';
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
  final ResourceType resourceType = comic.resourceType;
  if (resourceType == ResourceType.epub ||
      resourceType == ResourceType.zip ||
      resourceType == ResourceType.cbz) {
    try {
      final String sourceNorm = normalizeArchiveCoverSourcePath(comic.path);
      final bool useDiskCache = ref.read(archiveCoverDiskCacheEnabledProvider);
      final ArchiveCoverCache coverCache = ref.read(archiveCoverCacheProvider);
      if (useDiskCache) {
        final String? cachedPath = await coverCache.tryReadValidPath(
          comicId: comicId,
          sourcePathNormalized: sourceNorm,
        );
        if (cachedPath != null) {
          return ComicCoverDisplayData.file(cachedPath);
        }
      }
      final ArchiveCoverDecodeResult decoded =
          await loadArchiveCoverDecodeResultOffMainUi(
            path: comic.path,
            type: resourceType,
          );
      final Uint8List? bytes = decoded.bytes;
      if (bytes != null && bytes.isNotEmpty) {
        if (useDiskCache) {
          final String? writtenPath = await coverCache.write(
            comicId: comicId,
            sourcePathNormalized: sourceNorm,
            bytes: bytes,
            fileExtension: decoded.fileExtension,
          );
          if (writtenPath != null) {
            return ComicCoverDisplayData.file(writtenPath);
          }
        }
        return ComicCoverDisplayData.bytes(bytes);
      }
      return null;
    } on Object catch (error, stackTrace) {
      LogManager.instance.handle(
        error,
        stackTrace,
        '加载漫画封面失败(isolate): comicId=$comicId, path=${comic.path}, type=$resourceType',
      );
      return null;
    }
  }
  final ReadResourceGetService readResourceService = ref.read(
    readResourceGetServiceProvider,
  );
  try {
    final ComicReadResourceAccessor accessor = await readResourceService
        .acquire(comicId: comicId, path: comic.path, type: resourceType);
    final ReaderImage cover = await accessor.getCoverImage();
    if (cover is ReaderFileImage) {
      return ComicCoverDisplayData.file(cover.file.path);
    }
    if (cover is ReaderBytesImage) {
      return ComicCoverDisplayData.bytes(cover.bytes);
    }
    return null;
  } on Object catch (error, stackTrace) {
    LogManager.instance.handle(
      error,
      stackTrace,
      '加载漫画封面失败: comicId=$comicId, path=${comic.path}, type=${comic.resourceType}',
    );
    return null;
  }
}
