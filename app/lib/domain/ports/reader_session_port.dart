import 'package:hentai_library/domain/models/entity/comic/comic.dart';

/// Rust 阅读会话生命周期 seam。
abstract class ReaderSessionPort {
  Future<void> openComic(Comic comic);

  Future<void> closeComic(String comicId);

  /// Library sync 后清理全部阅读会话缓存。
  Future<void> clear();
}
