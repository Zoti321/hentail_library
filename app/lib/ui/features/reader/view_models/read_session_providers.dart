import 'dart:io';
import 'dart:typed_data';

import 'package:hentai_library/core/logging/log_manager.dart';
import 'package:hentai_library/data/adapters/reader_frb_mapper.dart';
import 'package:hentai_library/domain/models/entity/comic/comic.dart';
import 'package:hentai_library/domain/reading/read_session_exceptions.dart';
import 'package:hentai_library/domain/models/entity/reading_history.dart';
import 'package:hentai_library/domain/reading/read_session_page.dart';
import 'package:hentai_library/domain/reading/reader_session_snapshot.dart';
import 'package:hentai_library/src/rust/api/init.dart';
import 'package:hentai_library/src/rust/api/reader.dart' as rust;
import 'package:hentai_library/ui/features/reader/view_models/read_session_page_data.dart';
import 'package:hentai_library/ui/features/shell/di/deps.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'read_session_providers.g.dart';

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
Future<ReaderSessionSnapshot> readerSessionOpen(
  Ref ref, {
  required String comicId,
  bool incognito = false,
}) {
  return ref
      .read(readerSessionServiceProvider)
      .open(comicId: comicId, incognito: incognito);
}

@Riverpod()
Future<List<ReaderPageImageData>> comicImages(
  Ref ref, {
  required String comicId,
  String? chapterId,
}) async {
  final List<ReadSessionPage> pages = await ref
      .read(readerSessionServiceProvider)
      .loadPages(comicId);
  return pages.map(_mapReadSessionPageToUi).toList(growable: false);
}

@Riverpod()
Future<rust.ReaderPageDto> comicReaderPage(
  Ref ref, {
  required String comicId,
  required int pageIndex,
}) async {
  final Comic? comic = await ref.read(comicRepoProvider).findById(comicId);
  if (comic == null) {
    throw StateError('漫画不存在: $comicId');
  }
  try {
    return rust.loadReaderPageFrb(
      comicId: comic.comicId,
      path: comic.path,
      resourceType: mapResourceType(comic.resourceType),
      pageIndex: pageIndex,
    );
  } on HentaiErrorDto catch (error, stackTrace) {
    throw ReadSessionPageLoadException.loadFailed(
      comicId: comicId,
      path: comic.path,
      cause: error,
      stackTrace: stackTrace,
    );
  }
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
        .read(readerSessionServiceProvider)
        .loadPageBytes(comic: comic, archivePageIndex: pageIndex);
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
