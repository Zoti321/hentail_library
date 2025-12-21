import 'package:hentai_library/core/util/path_normalizer.dart';

/// 阅读资源模块路径标准化：基于全局 [PathNormalizer] 的 key 规范。
class ComicReadPathNormalizer {
  const ComicReadPathNormalizer();

  String normalizePath(String rawPath) {
    return const PathNormalizer().normalizeForKey(rawPath);
  }
}
