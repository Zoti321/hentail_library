import 'dart:io';
import 'dart:typed_data';

/// 阅读资源领域模型：统一描述单页图像载荷。
///
/// - 目录资源使用 [ReaderFileImage]
/// - 压缩包/EPUB 资源使用 [ReaderBytesImage]
sealed class ReaderImage {
  const ReaderImage();
}

/// 指向本地文件系统中的图片文件（通常来自目录型漫画）。
final class ReaderFileImage extends ReaderImage {
  const ReaderFileImage(this.file);

  final File file;
}

/// 承载内存中的图片字节（通常来自 zip/cbz/epub）。
final class ReaderBytesImage extends ReaderImage {
  const ReaderBytesImage(this.bytes, {this.mimeType});

  final Uint8List bytes;
  final String? mimeType;
}

