import 'dart:typed_data';

import 'package:hentai_library/data/services/comic/read_resource_get/api/read_resource_get_service.dart';
import 'package:hentai_library/data/services/comic/read_resource_get/core/comic_read_resource_accessor.dart';
import 'package:hentai_library/data/services/comic/read_resource_get/core/reader_image.dart';
import 'package:hentai_library/domain/models/entity/comic/comic.dart';
import 'package:hentai_library/domain/models/enums.dart';
import 'package:hentai_library/domain/ports/comic_page_source_port.dart';
import 'package:hentai_library/domain/reading/read_session_page.dart';

/// [ComicPageSourcePort] 的 data 层 adapter。
class ComicPageSourceAdapter implements ComicPageSourcePort {
  const ComicPageSourceAdapter({
    required ReadResourceGetService readResourceGetService,
  }) : _readResourceGetService = readResourceGetService;

  final ReadResourceGetService _readResourceGetService;

  @override
  Future<List<ReadSessionPage>> loadPages(Comic comic) async {
    final ComicReadResourceAccessor accessor = await _readResourceGetService
        .acquire(
          comicId: comic.comicId,
          path: comic.path,
          type: comic.resourceType,
        );
    final int total = accessor.pageCount;
    if (total <= 0) {
      return const <ReadSessionPage>[];
    }
    if (comic.resourceType == ResourceType.dir) {
      final List<ReadSessionPage> pages = <ReadSessionPage>[];
      for (int i = 0; i < total; i++) {
        final ReaderImage image = await accessor.getPageImage(i);
        if (image is ReaderFileImage) {
          pages.add(ReadSessionDirPage(image.file.path));
        }
      }
      return pages;
    }
    return List<ReadSessionPage>.generate(
      total,
      (int index) => ReadSessionArchivePage(
        comicId: comic.comicId,
        pageIndex: index,
      ),
    );
  }

  @override
  Future<Uint8List?> loadPageBytes({
    required Comic comic,
    required int pageIndex,
  }) async {
    if (comic.resourceType == ResourceType.dir) {
      return null;
    }
    final ComicReadResourceAccessor accessor = await _readResourceGetService
        .acquire(
          comicId: comic.comicId,
          path: comic.path,
          type: comic.resourceType,
        );
    final ReaderImage image = await accessor.getPageImage(pageIndex);
    if (image is ReaderBytesImage) {
      return image.bytes;
    }
    if (image is ReaderFileImage) {
      return image.file.readAsBytes();
    }
    return null;
  }
}
