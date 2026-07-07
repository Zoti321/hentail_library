import 'dart:io';

import 'package:hentai_library/domain/models/entity/reading_history.dart';
import 'package:hentai_library/domain/reading/read_session_page.dart';
import 'package:hentai_library/domain/reading/reader_page_payload.dart';
import 'package:hentai_library/domain/reading/reader_session_snapshot.dart';
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
Future<ReaderPagePayload> comicReaderPage(
  Ref ref, {
  required String comicId,
  required int pageIndex,
}) {
  return ref.read(readerSessionServiceProvider).loadReaderPage(
    comicId: comicId,
    archivePageIndex: pageIndex,
  );
}

@Riverpod()
Future<ReadingHistory?> readingProgress(
  Ref ref, {
  required String comicId,
}) async {
  return ref.watch(readingHistoryRepoProvider).getByComicId(comicId);
}
