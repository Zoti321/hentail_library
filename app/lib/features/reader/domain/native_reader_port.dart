import 'package:hentai_library/shared/domain/models/entity/comic/comic.dart';

/// Rust reader 资源生命周期 seam（open/close/clear；非 Dart [ReadSession] 实体）。
abstract class NativeReaderPort {
  Future<void> openComic(Comic comic);

  Future<void> closeComic(String comicId);

  /// Library sync 后清理全部 native reader 缓存。
  Future<void> clear();
}
