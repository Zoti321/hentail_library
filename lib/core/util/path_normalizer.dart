import 'package:path/path.dart' as p;

/// 跨平台路径规范化工具（Windows / Android / macOS / iOS / Linux）。
///
/// 约定：
/// - 文件系统访问使用 [normalizeForFileSystem]
/// - 比较、去重、缓存键使用 [normalizeForKey]
class PathNormalizer {
  const PathNormalizer();

  /// 规范化为当前平台可访问的路径格式。
  String normalizeForFileSystem(String rawPath) {
    final String trimmed = rawPath.trim();
    if (trimmed.isEmpty) {
      return '';
    }
    return p.normalize(trimmed);
  }

  /// 规范化为跨平台稳定的比较键路径（统一 `/`）。
  String normalizeForKey(String rawPath, {bool shouldLowerCase = false}) {
    final String normalizedFsPath = normalizeForFileSystem(rawPath);
    if (normalizedFsPath.isEmpty) {
      return '';
    }
    final String posixPath = p.posix.normalize(
      normalizedFsPath.replaceAll('\\', '/'),
    );
    final String withoutTrailingSlash = _trimTrailingSlash(posixPath);
    if (!shouldLowerCase) {
      return withoutTrailingSlash;
    }
    return withoutTrailingSlash.toLowerCase();
  }

  String _trimTrailingSlash(String normalizedPosixPath) {
    if (normalizedPosixPath == '/' ||
        RegExp(r'^[A-Za-z]:/$').hasMatch(normalizedPosixPath)) {
      return normalizedPosixPath;
    }
    String current = normalizedPosixPath;
    while (current.endsWith('/')) {
      current = current.substring(0, current.length - 1);
    }
    return current;
  }
}

