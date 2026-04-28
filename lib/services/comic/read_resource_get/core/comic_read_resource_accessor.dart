import 'package:hentai_library/services/comic/read_resource_get/core/reader_image.dart';

/// 已打开的漫画阅读资源访问器。
///
/// 约束调用顺序：
/// 1. 先调用 [prepare]
/// 2. 再访问 [pageCount] / [getCoverImage] / [getPageImage]
/// 3. 会话结束后调用 [dispose]
abstract class ComicReadResourceAccessor {
  /// 预加载资源并建立稳定阅读顺序。
  Future<void> prepare();

  /// 可阅读页数（正文页数）。
  int get pageCount;

  /// 释放访问器内部缓存资源。
  Future<void> dispose();

  /// 获取封面图。
  Future<ReaderImage> getCoverImage();

  /// 获取指定页图像（从 0 开始）。
  Future<ReaderImage> getPageImage(int pageIndex);
}

