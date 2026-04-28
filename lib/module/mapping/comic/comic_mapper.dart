import 'package:hentai_library/core/util/utils.dart';
import 'package:hentai_library/data/services/comic/scan/resource_types.dart';
import 'package:hentai_library/model/entity/comic/author.dart';
import 'package:hentai_library/model/entity/comic/comic.dart';
import 'package:path/path.dart' as p;

/// ParsedResource 映射为领域 `Comic`。
class ComicMapper {
  const ComicMapper();

  /// 规范化路径用于生成稳定的（path-based）comicId。
  ///
  /// 约定：
  /// - 统一分隔符
  /// - 去掉末尾分隔符
  String normalizePath(String rawPath) {
    String normalized = p.normalize(rawPath);
    normalized = normalized.replaceAll('\\', '/');
    while (normalized.endsWith('/')) {
      normalized = normalized.substring(0, normalized.length - 1);
    }
    return normalized;
  }

  String comicIdFromPath(String path) {
    final String normalized = normalizePath(path);
    return generateComicId(normalized);
  }

  Comic fromParsedResource(ParsedResource resource) {
    return Comic(
      comicId: comicIdFromPath(resource.path),
      path: resource.path,
      resourceType: resource.type,
      title: resource.meta.title,
      authors: resource.meta.authors.map((name) => Author(name: name)).toList(),
      pageCount: resource.meta.pageCount,
    );
  }
}

