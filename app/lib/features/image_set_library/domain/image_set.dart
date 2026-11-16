/// Image set：库内一级子目录或库根图集（GLOSSARY）。
class ImageSet {
  const ImageSet({
    required this.imageSetId,
    required this.libraryId,
    required this.relativePath,
    required this.name,
    required this.isRoot,
  });

  final String imageSetId;
  final String libraryId;

  /// `/` 分隔的库根相对路径；库根图集为空。
  final String relativePath;

  /// 目录名；库根图集为空。
  final String name;
  final bool isRoot;
}
