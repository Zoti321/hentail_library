/// 从 Image set 缩略图发起 Reader 的入口参数（Reader session 由 #586 实现）。
class ImageSetReaderEntry {
  const ImageSetReaderEntry({
    required this.libraryId,
    required this.imageSetId,
    required this.imageSetImageId,
    required this.index,
  });

  final String libraryId;
  final String imageSetId;
  final String imageSetImageId;

  /// 在所属 Image set 中的顺序位置（从 0 开始）。
  final int index;
}
