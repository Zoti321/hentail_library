import 'dart:typed_data';

/// 封面展示数据：目录漫画为磁盘路径，归档为内存图像字节。
final class ComicCoverImage {
  const ComicCoverImage.file(String path)
    : filePath = path,
      memoryBytes = null;

  const ComicCoverImage.bytes(Uint8List bytes)
    : filePath = null,
      memoryBytes = bytes;

  final String? filePath;
  final Uint8List? memoryBytes;
}
