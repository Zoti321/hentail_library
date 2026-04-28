import 'dart:io';
import 'dart:typed_data';

/// 表现层可用的单张图片载荷：目录资源为 [ReaderFileImage]，归档为内存字节。
sealed class ReaderImage {
  const ReaderImage();
}

/// 磁盘上的漫画图片（例如纯图片目录）。
final class ReaderFileImage extends ReaderImage {
  const ReaderFileImage(this.file);

  final File file;
}

/// 从压缩包/EPUB 等容器读取的内存图像（无落盘）。
final class ReaderBytesImage extends ReaderImage {
  const ReaderBytesImage(this.bytes, {this.mimeType});

  final Uint8List bytes;
  final String? mimeType;
}
