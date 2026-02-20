import 'package:hentai_library/data/services/comic/read_resource_get/reader_image.dart';

/// 已打开的漫画资源会话：按阅读顺序提供封面与分页图像。
abstract class ComicReadResourceAccessor {
  /// 枚举容器内图片、建立顺序；必须先成功完成后再使用 [pageCount] 与读图方法。
  Future<void> prepare();

  /// 可阅读页数（正文页数；需先 [prepare]）。
  int get pageCount;

  /// 释放容器侧缓存（如整包解码结果）。
  Future<void> dispose();

  /// 封面图（目录为 [ReaderFileImage]，归档为 [ReaderBytesImage]）。
  Future<ReaderImage> getCoverImage();

  /// 正文第 [pageIndex] 页，从 0 开始。
  Future<ReaderImage> getPageImage(int pageIndex);
}
