import 'package:hentai_library/domain/enums/enums.dart';

/// 统一的漫画/来源文件类型与扩展名常量。
///
/// 约定：
/// - 扩展名均为小写且包含前导 `.`，例如 `.jpg`、`.epub`
/// - 调用方一般使用 `path.extension(path).toLowerCase()` 后直接与这些常量匹配。
class ComicFileTypes {
  ComicFileTypes._();

  /// 顶层目录漫画的图片后缀集合（用于目录封面/页数统计）。
  static const Set<String> comicImageExtensions = {
    '.jpg',
    '.jpeg',
    '.png',
    '.webp',
    '.bmp',
  };

  /// ZIP 扫描可解析集合（ComicScannerStrategy：用于 `.cbz/.zip`）。
  static const Set<String> zipArchiveExtensions = {
    '.cbz',
    '.zip',
  };

  /// 视为压缩包归档的扩展名集合（用于同步报告类型推断、封面修复路径判断等）。
  /// 注意：ZIP 类扫描策略目前仅实现 `.cbz/.zip`；`.cbr/.rar` 常归类为压缩包但扫描时跳过。
  static const Set<String> comicArchiveExtensions = {
    '.cbz',
    '.zip',
    '.cbr',
    '.rar',
  };

  /// EPUB 扩展名集合。
  static const Set<String> epubExtensions = {
    '.epub',
  };
}

// 导出一组更简短的别名，便于在其它文件中使用。
const comicImageExtensions = ComicFileTypes.comicImageExtensions;
const zipArchiveExtensions = ComicFileTypes.zipArchiveExtensions;
const comicArchiveExtensions = ComicFileTypes.comicArchiveExtensions;
const epubExtensions = ComicFileTypes.epubExtensions;

/// 根据路径扩展名推断扫描项类型（目录或其它非上述扩展名归为 [ScannedItemType.dir]）。
ScannedItemType scannedItemTypeFromPath(String path) {
  final lower = path.toLowerCase();
  if (epubExtensions.any((ext) => lower.endsWith(ext))) {
    return ScannedItemType.epub;
  }
  if (lower.endsWith('.cbz')) {
    return ScannedItemType.cbz;
  }
  if (lower.endsWith('.zip') || lower.endsWith('.cbr') || lower.endsWith('.rar')) {
    return ScannedItemType.zip;
  }
  return ScannedItemType.dir;
}

