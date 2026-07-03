import 'package:hentai_library/domain/models/enums.dart';

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
    '.gif',
  };

  /// ZIP 扫描可解析集合（ComicScannerStrategy：用于 `.cbz/.zip`）。
  static const Set<String> zipArchiveExtensions = {'.cbz', '.zip'};

  /// 视为压缩包归档的扩展名集合（用于同步报告类型推断、封面修复路径判断等）。
  static const Set<String> comicArchiveExtensions = {
    '.cbz',
    '.zip',
    '.cbr',
    '.rar',
    '.cb7',
    '.7z',
  };

  /// EPUB 扩展名集合。
  static const Set<String> epubExtensions = {'.epub'};

  /// PDF 扩展名集合。
  static const Set<String> pdfExtensions = {'.pdf'};
}

// 导出一组更简短的别名，便于在其它文件中使用。
const comicImageExtensions = ComicFileTypes.comicImageExtensions;
const zipArchiveExtensions = ComicFileTypes.zipArchiveExtensions;
const comicArchiveExtensions = ComicFileTypes.comicArchiveExtensions;
const epubExtensions = ComicFileTypes.epubExtensions;
const pdfExtensions = ComicFileTypes.pdfExtensions;

/// 根据路径扩展名推断扫描项类型（目录或其它非上述扩展名归为 [ResourceType.dir]）。
ResourceType scannedItemTypeFromPath(String path) {
  final lower = path.toLowerCase();
  if (epubExtensions.any((ext) => lower.endsWith(ext))) {
    return ResourceType.epub;
  }
  if (pdfExtensions.any((ext) => lower.endsWith(ext))) {
    return ResourceType.pdf;
  }
  if (lower.endsWith('.cbz')) {
    return ResourceType.cbz;
  }
  if (lower.endsWith('.cb7')) {
    return ResourceType.cb7;
  }
  if (lower.endsWith('.7z')) {
    return ResourceType.sevenZ;
  }
  if (lower.endsWith('.cbr')) {
    return ResourceType.cbr;
  }
  if (lower.endsWith('.rar')) {
    return ResourceType.rar;
  }
  if (lower.endsWith('.zip')) {
    return ResourceType.zip;
  }
  return ResourceType.dir;
}
