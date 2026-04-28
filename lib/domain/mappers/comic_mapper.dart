import 'package:hentai_library/core/util/utils.dart';
import 'package:hentai_library/data/services/comic/scan/resource_types.dart';
import 'package:hentai_library/model/entity/comic/author.dart';
import 'package:hentai_library/model/entity/comic/comic.dart';
import 'package:path/path.dart' as p;

///  ParsedResource 映射为领域 `Comic`。
class ComicMapper {
  /// 规范化路径用于生成稳定的（path-based）comicId。
  ///
  /// 约定：
  /// - 统一分隔符
  /// - 去掉末尾分隔符
  String normalizePath(String rawPath) {
    var n = p.normalize(rawPath);
    n = n.replaceAll('\\', '/');
    while (n.endsWith('/')) {
      n = n.substring(0, n.length - 1);
    }
    return n;
  }

  String comicIdFromPath(String path) {
    final normalized = normalizePath(path);
    return generateComicId(normalized);
  }

  Comic fromParsedResource(ParsedResource r) {
    return Comic(
      comicId: comicIdFromPath(r.path),
      path: r.path,
      resourceType: r.type,
      title: r.meta.title,
      authors: r.meta.authors.map((n) => Author(name: n)).toList(),
      pageCount: r.meta.pageCount,
    );
  }
}
