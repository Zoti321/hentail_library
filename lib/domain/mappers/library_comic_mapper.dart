import 'package:hentai_library/core/util/utils.dart';
import 'package:hentai_library/data/services/comic/resource_types.dart';
import 'package:hentai_library/domain/entity/comic/library_comic.dart';
import 'package:path/path.dart' as p;

/// 将 v2 ParsedResource 映射为领域 `LibraryComic`。
class LibraryComicMapper {
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
    // 复用现有 sha1 生成工具：输入放到 title 参数位（仅作 hash）。
    return generateComicId(normalized);
  }

  LibraryComic fromParsedResource(ParsedResource r) {
    return LibraryComic(
      comicId: comicIdFromPath(r.path),
      path: r.path,
      resourceType: r.type,
      title: r.meta.title,
      authors: r.meta.authors,
    );
  }
}
