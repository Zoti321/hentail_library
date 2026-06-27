import 'dart:typed_data';

import 'package:hentai_library/domain/models/entity/comic/comic.dart';
import 'package:hentai_library/domain/reading/read_session_page.dart';

/// 阅读会话页面来源 seam：acquire 与按页读取。
abstract class ComicPageSourcePort {
  Future<List<ReadSessionPage>> loadPages(Comic comic);

  Future<Uint8List?> loadPageBytes({
    required Comic comic,
    required int pageIndex,
  });
}
