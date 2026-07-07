import 'dart:typed_data';

/// ???????????????????????????
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
