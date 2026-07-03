import 'dart:typed_data';

import 'package:hentai_library/data/adapters/reader_frb_mapper.dart';
import 'package:hentai_library/domain/models/entity/comic/comic.dart';
import 'package:hentai_library/domain/models/enums.dart';
import 'package:hentai_library/domain/ports/comic_page_source_port.dart';
import 'package:hentai_library/domain/reading/read_session_page.dart';
import 'package:hentai_library/src/rust/api/init.dart';
import 'package:hentai_library/src/rust/api/reader.dart' as rust;

/// [ComicPageSourcePort] 经 Rust FRB 读取页面列表与归档页字节。
class ComicPageSourceFrbAdapter implements ComicPageSourcePort {
  const ComicPageSourceFrbAdapter();

  @override
  Future<List<ReadSessionPage>> loadPages(Comic comic) async {
    try {
      final rust.ReaderPageListDto pageList = rust.loadPageListFrb(
        comicId: comic.comicId,
        path: comic.path,
        resourceType: mapResourceType(comic.resourceType),
      );
      if (pageList.pageCount <= 0) {
        return const <ReadSessionPage>[];
      }
      if (comic.resourceType == ResourceType.dir) {
        return pageList.dirPagePaths
            .map(ReadSessionDirPage.new)
            .toList(growable: false);
      }
      return List<ReadSessionPage>.generate(
        pageList.pageCount,
        (int index) =>
            ReadSessionArchivePage(comicId: comic.comicId, pageIndex: index),
        growable: false,
      );
    } on HentaiErrorDto catch (error) {
      throwReaderException(
        error,
        resourceType: comic.resourceType,
        path: comic.path,
        comicId: comic.comicId,
      );
    }
  }

  @override
  Future<Uint8List?> loadPageBytes({
    required Comic comic,
    required int pageIndex,
  }) async {
    if (comic.resourceType == ResourceType.dir) {
      return null;
    }
    try {
      return rust.loadPageBytesFrb(
        comicId: comic.comicId,
        path: comic.path,
        resourceType: mapResourceType(comic.resourceType),
        pageIndex: pageIndex,
      );
    } on HentaiErrorDto catch (error) {
      throwReaderException(
        error,
        resourceType: comic.resourceType,
        path: comic.path,
        comicId: comic.comicId,
      );
    }
  }
}
