import 'dart:collection';

import 'package:hentai_library/data/services/comic/read_resource_get/comic_read_resource_accessor.dart';
import 'package:hentai_library/data/services/comic/read_resource_get/comic_read_resource_opener.dart';
import 'package:hentai_library/domain/util/enums.dart';

class _CachedSession {
  _CachedSession({required this.normalizedPath, required this.accessor});

  final String normalizedPath;
  final ComicReadResourceAccessor accessor;
}

/// 按 comicId 缓存 [ComicReadResourceAccessor]，避免归档类重复整包解码。
class ComicReadResourceSessionManager {
  ComicReadResourceSessionManager({required ComicReadResourceOpener opener})
    : _opener = opener;

  final ComicReadResourceOpener _opener;
  final LinkedHashMap<String, _CachedSession> _cache =
      LinkedHashMap<String, _CachedSession>();

  static const int _maxSessions = 4;

  String _normalizePath(String path) {
    return path.trim().replaceAll('\\', '/');
  }

  Future<ComicReadResourceAccessor> acquire({
    required String comicId,
    required String path,
    required ResourceType type,
  }) async {
    final String key = comicId;
    final String normalizedPath = _normalizePath(path);
    final _CachedSession? existing = _cache.remove(key);
    if (existing != null) {
      if (existing.normalizedPath == normalizedPath) {
        _cache[key] = existing;
        return existing.accessor;
      }
      await existing.accessor.dispose();
    }
    while (_cache.length >= _maxSessions) {
      final String firstKey = _cache.keys.first;
      final _CachedSession evicted = _cache.remove(firstKey)!;
      await evicted.accessor.dispose();
    }
    final ComicReadResourceAccessor accessor = await _opener.open(
      path: normalizedPath,
      type: type,
    );
    _cache[key] = _CachedSession(
      normalizedPath: normalizedPath,
      accessor: accessor,
    );
    return accessor;
  }

  Future<void> clear() async {
    for (final _CachedSession s in _cache.values) {
      await s.accessor.dispose();
    }
    _cache.clear();
  }
}
