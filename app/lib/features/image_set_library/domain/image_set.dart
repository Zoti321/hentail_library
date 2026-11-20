/// Image set：库内一级子目录或库根图集（GLOSSARY）。
class ImageSet {
  const ImageSet({
    required this.imageSetId,
    required this.libraryId,
    required this.relativePath,
    required this.name,
    required this.isRoot,
    this.nameLocked = false,
  });

  final String imageSetId;
  final String libraryId;

  /// `/` 分隔的库根相对路径；库根图集为空。
  final String relativePath;

  /// 显示名；同步扫描来源为目录名或压缩包文件名。
  final String name;
  final bool isRoot;

  /// 名称的 Metadata field lock；锁定时同步保留用户名称。
  final bool nameLocked;

  ImageSet copyWith({String? name, bool? nameLocked}) => ImageSet(
    imageSetId: imageSetId,
    libraryId: libraryId,
    relativePath: relativePath,
    name: name ?? this.name,
    isRoot: isRoot,
    nameLocked: nameLocked ?? this.nameLocked,
  );
}
