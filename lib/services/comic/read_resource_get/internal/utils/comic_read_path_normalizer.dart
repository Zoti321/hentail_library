/// 路径标准化工具：统一去空白并转为 `/` 分隔符。
class ComicReadPathNormalizer {
  const ComicReadPathNormalizer();

  String normalizePath(String rawPath) {
    return rawPath.trim().replaceAll('\\', '/');
  }
}

