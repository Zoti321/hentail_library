import 'dart:io';
import 'dart:typed_data';

import 'package:hentai_library/features/reader/data/mappers/reader_frb_mapper.dart';
import 'package:hentai_library/features/reader/domain/reader_comic_ref.dart';
import 'package:hentai_library/shared/domain/models/enums.dart';
import 'package:hentai_library/features/reader/domain/comic_page_source_port.dart';
import 'package:hentai_library/features/reader/domain/read_session_page.dart';
import 'package:hentai_library/features/reader/domain/reader_page_payload.dart';
import 'package:hentai_library/src/rust/api/init.dart';
import 'package:hentai_library/src/rust/api/reader.dart' as rust;

/// [ComicPageSourcePort] 经 Rust FRB 读取页面列表与归档页字节。
class ComicPageSourceFrbAdapter implements ComicPageSourcePort {
  const ComicPageSourceFrbAdapter();

  @override
  Future<List<ReadSessionPage>> loadPages(ReaderComicRef comic) async {
    try {
      // 会话须已 open；列表从 session 取 path/type。
      final rust.ReaderPageListDto pageList = await rust.loadPageListFrb(
        comicId: comic.comicId,
      );
      if (pageList.pageCount <= 0) {
        return const <ReadSessionPage>[];
      }
      if (comic.resourceType == ResourceType.dir) {
        return List<ReadSessionPage>.generate(
          pageList.dirPagePaths.length,
          (int index) => ReadSessionDirPage(
            filePath: pageList.dirPagePaths[index],
            pageIndex: index,
          ),
          growable: false,
        );
      }
      return List<ReadSessionPage>.generate(
        pageList.pageCount,
        (int index) =>
            ReadSessionArchivePage(comicId: comic.comicId, pageIndex: index),
        growable: false,
      );
    } on HentaiErrorDto catch (error) {
      throwReaderException(error, path: comic.path, comicId: comic.comicId);
    }
  }

  @override
  Future<Uint8List?> loadPageBytes({
    required String comicId,
    required int pageIndex,
  }) async {
    try {
      // Dir：Rust load_page_bytes 拒绝目录；先走 loadReaderPage 再读文件。
      final ReaderPagePayload page = await loadReaderPage(
        comicId: comicId,
        pageIndex: pageIndex,
      );
      return switch (page) {
        ReaderPageFilePath(:final String path) => await File(
          path,
        ).readAsBytes(),
        ReaderPageBytes(:final Uint8List data) => data,
      };
    } on HentaiErrorDto catch (error) {
      throwReaderException(error, comicId: comicId);
    }
  }

  @override
  Future<ReaderPagePayload> loadReaderPage({
    required String comicId,
    required int pageIndex,
  }) async {
    try {
      final rust.ReaderPageDto page = await rust.loadReaderPageFrb(
        comicId: comicId,
        pageIndex: pageIndex,
      );
      return switch (page) {
        rust.ReaderPageDto_FilePath(:final String path) => ReaderPageFilePath(
          path,
        ),
        rust.ReaderPageDto_Bytes(:final Uint8List data) => ReaderPageBytes(
          data,
        ),
      };
    } on HentaiErrorDto catch (error) {
      throwReaderException(error, comicId: comicId);
    }
  }

  @override
  Future<void> prefetchPages({
    required String comicId,
    required List<int> pageIndexes,
    required int generation,
  }) async {
    if (pageIndexes.isEmpty) {
      return;
    }
    try {
      await rust.prefetchReaderPagesFrb(
        comicId: comicId,
        pageIndexes: pageIndexes,
        generation: BigInt.from(generation),
      );
    } on HentaiErrorDto catch (error) {
      throwReaderException(error, comicId: comicId);
    }
  }

  @override
  Future<void> clearPageCache({required String comicId}) {
    return rust.clearReaderPageCacheFrb(comicId: comicId);
  }
}
