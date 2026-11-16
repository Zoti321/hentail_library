/// Image set image：指向物理位置（loose 路径或压缩包路径 + 条目路径）的图片记录。
class ImageSetImage {
  const ImageSetImage({
    required this.imageSetImageId,
    required this.imageSetId,
    required this.libraryId,
    required this.carrierRelativePath,
    required this.memberPath,
    required this.carrierKind,
    required this.name,
  });

  final String imageSetImageId;
  final String imageSetId;
  final String libraryId;
  final String carrierRelativePath;

  /// loose 图片为空；压缩包内为条目路径。
  final String memberPath;

  /// `loose` | `zip` | `rar` | `sevenz`。
  final String carrierKind;
  final String name;
}
