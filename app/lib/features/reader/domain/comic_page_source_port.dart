import 'dart:typed_data';

import 'package:hentai_library/shared/domain/models/entity/comic/comic.dart';
import 'package:hentai_library/features/reader/domain/read_session_page.dart';
import 'package:hentai_library/features/reader/domain/reader_page_payload.dart';

/// 阅读会话页面来源 seam：acquire 与按页读取。
///
/// 会话 open 之后的 load/prefetch 仅需 [comicId]（path/type 由 native session 持有）。
abstract class ComicPageSourcePort {
  Future<List<ReadSessionPage>> loadPages(Comic comic);

  Future<Uint8List?> loadPageBytes({
    required String comicId,
    required int pageIndex,
  });

  /// [pageIndex] 为 0-based 归档页索引。
  Future<ReaderPagePayload> loadReaderPage({
    required String comicId,
    required int pageIndex,
  });

  /// [pageIndexes] 为 0-based 归档页索引。
  Future<void> prefetchPages({
    required String comicId,
    required List<int> pageIndexes,
    required int generation,
  });

  Future<void> clearPageCache({required String comicId});
}
