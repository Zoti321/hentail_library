import 'package:path/path.dart' as p;

/// 根据文件路径或文件名推断漫画图片 MIME（未知返回 null）。
String? inferComicImageMimeType(String filePathOrName) {
  final String ext = p.extension(filePathOrName).toLowerCase();
  return switch (ext) {
    '.jpg' || '.jpeg' => 'image/jpeg',
    '.png' => 'image/png',
    '.webp' => 'image/webp',
    '.gif' => 'image/gif',
    '.bmp' => 'image/bmp',
    '.avif' => 'image/avif',
    _ => null,
  };
}

