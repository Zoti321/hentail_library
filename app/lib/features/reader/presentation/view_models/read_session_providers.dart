import 'dart:io';

import 'package:hentai_library/features/reader/domain/opened_read_session.dart';
import 'package:hentai_library/features/reader/domain/read_session_page.dart';
import 'package:hentai_library/features/reader/domain/read_session_source.dart';
import 'package:hentai_library/features/reader/domain/reader_page_payload.dart';
import 'package:hentai_library/features/reader/presentation/providers/session_providers.dart';
import 'package:hentai_library/features/reader/presentation/view_models/read_session_page_data.dart';
import 'package:hentai_library/features/reading_history/public.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'read_session_providers.g.dart';

ReaderPageImageData _mapReadSessionPageToUi(ReadSessionPage page) {
  return switch (page) {
    ReadSessionDirPage(:final String filePath, :final int pageIndex) =>
      ReaderDirPageImageData(File(filePath), pageIndex: pageIndex),
    ReadSessionArchivePage(:final String comicId, :final int pageIndex) =>
      ReaderArchivePageImageData(comicId: comicId, pageIndex: pageIndex),
    ReadSessionImageSetPage(:final page) => ReaderImageSetPageImageData(
      page: page,
    ),
  };
}

@Riverpod()
Future<OpenedReadSession> readerSessionOpen(
  Ref ref, {
  required String comicId,
  bool incognito = false,
  bool startFromFirstPage = false,
}) {
  return readerSessionOpenFromSource(
    ref,
    source: ComicReadSessionSource(comicId),
    incognito: incognito,
    startFromFirstPage: startFromFirstPage,
  );
}

@Riverpod()
Future<OpenedReadSession> readerSessionOpenFromSource(
  Ref ref, {
  required ReadSessionSource source,
  bool incognito = false,
  bool startFromFirstPage = false,
}) {
  return ref
      .read(openReadSessionUseCaseProvider)
      .openFromSource(
        source,
        incognito: incognito,
        startFromFirstPage: startFromFirstPage,
      );
}

@Riverpod()
Future<List<ReaderPageImageData>> sessionPages(
  Ref ref, {
  required ReadSessionSource source,
}) async {
  final List<ReadSessionPage> pages = await ref
      .read(openReadSessionUseCaseProvider)
      .loadPages(source);
  return pages.map(_mapReadSessionPageToUi).toList(growable: false);
}

/// Comic convenience / legacy viewport key. Prefer [sessionPages] with source.
@Riverpod()
Future<List<ReaderPageImageData>> comicImages(
  Ref ref, {
  required String comicId,
  String? chapterId,
}) async {
  final service = ref.read(openReadSessionUseCaseProvider);
  final ReadSessionSource source =
      service.openedSource(comicId) ?? ComicReadSessionSource(comicId);
  return sessionPages(ref, source: source);
}

/// 会话内 keepAlive：翻页回看不因 autoDispose 重载；退出阅读器时由 prefetch clear invalidate。
@Riverpod(keepAlive: true)
Future<ReaderPagePayload> sessionReaderPage(
  Ref ref, {
  required String sessionKey,
  required int pageIndex,
}) {
  return ref
      .read(openReadSessionUseCaseProvider)
      .loadReaderPage(sessionKey: sessionKey, archivePageIndex: pageIndex);
}

/// Legacy name for [sessionReaderPage].
@Riverpod(keepAlive: true)
Future<ReaderPagePayload> comicReaderPage(
  Ref ref, {
  required String comicId,
  required int pageIndex,
}) {
  return sessionReaderPage(ref, sessionKey: comicId, pageIndex: pageIndex);
}

@Riverpod()
Future<int?> readingProgress(Ref ref, {required String comicId}) {
  return ref.read(readResumePageQueryProvider)(comicId);
}
