import 'package:path/path.dart' as p;

/// 内容分级（用户自定义为主）。
enum ContentRating { unknown, safe, r18 }

/// 通过规则校验后确定的资源类型（用于后续 diff/入库重构）。
enum ResourceType {
  /// 纯图片目录
  dir,

  /// .zip 压缩包
  /// 内容为纯图片
  zip,

  /// .cbz 压缩包
  cbz,

  /// .epub 电子书
  /// 确认内容是否为漫画
  epub,

  /// .cbr 压缩包
  cbr,

  /// .rar 压缩包
  rar,

  /// .cb7 压缩包
  cb7,

  /// .7z 压缩包
  sevenZ,

  /// PDF 文档
  pdf;

  static ResourceType? fromFilePath(String path) {
    final String ext = p.extension(path).toLowerCase();
    return switch (ext) {
      '.zip' => ResourceType.zip,
      '.cbz' => ResourceType.cbz,
      '.epub' => ResourceType.epub,
      '.cbr' => ResourceType.cbr,
      '.rar' => ResourceType.rar,
      '.cb7' => ResourceType.cb7,
      '.7z' => ResourceType.sevenZ,
      '.pdf' => ResourceType.pdf,
      _ => null,
    };
  }
}

enum LibraryDisplayTarget { all, comics, series }
