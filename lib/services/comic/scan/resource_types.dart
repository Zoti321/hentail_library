import 'package:hentai_library/model/enums.dart';
import 'package:path/path.dart' as p;

/// 从资源中提取的元数据。
typedef ComicMeta = ({String title, List<String> authors, int? pageCount});

/// 解析阶段输出的基础单元。
typedef ParsedResource = ({String path, ResourceType type, ComicMeta meta});

ResourceType? resourceTypeFromFilePath(String path) {
  final ext = p.extension(path).toLowerCase();
  return switch (ext) {
    '.zip' => ResourceType.zip,
    '.cbz' => ResourceType.cbz,
    '.epub' => ResourceType.epub,
    '.cbr' => ResourceType.cbr,
    '.rar' => ResourceType.rar,
    _ => null,
  };
}
