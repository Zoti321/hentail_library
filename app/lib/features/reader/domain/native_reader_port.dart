import 'package:hentai_library/features/reader/domain/reader_comic_ref.dart';

/// Rust reader 资源生命周期 seam（open/close/clear；非 Dart [ReadSession] 实体）。
abstract class NativeReaderPort {
  Future<void> openComic(ReaderComicRef comic);

  Future<void> closeComic(String comicId);

  /// Library sync 后清理全部 native reader 缓存。
  Future<void> clear();
}
