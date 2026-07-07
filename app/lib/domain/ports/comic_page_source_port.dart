import 'dart:typed_data';

import 'package:hentai_library/domain/models/entity/comic/comic.dart';
import 'package:hentai_library/domain/reading/read_session_page.dart';
import 'package:hentai_library/domain/reading/reader_page_payload.dart';

/// 阅读会话页面来源 seam：acquire 与按页读取。
abstract class ComicPageSourcePort {
  Future<List<ReadSessionPage>> loadPages(Comic comic);

  Future<Uint8List?> loadPageBytes({
    required Comic comic,
    required int pageIndex,
  });

  /// [pageIndex] 为 0-based 归档页索引。
  Future<ReaderPagePayload> loadReaderPage({
    required Comic comic,
    required int pageIndex,
  });

  /// [pageIndexes] 为 0-based 归档页索引。
  Future<void> prefetchPages({
    required Comic comic,
    required List<int> pageIndexes,
    required int generation,
  });

  void clearPageCache({required String comicId});
}
