import 'dart:typed_data';

/// 计算以 [centerPageOneBased] 为中心的预加载页码集合（1-based）。
Set<int> computePrefetchWindow({
  required int centerPageOneBased,
  required int totalPages,
  required int neighborCount,
  Iterable<int> extraPageIndexesOneBased = const <int>[],
}) {
  if (totalPages <= 0) {
    return <int>{};
  }
  final int safeCenter = centerPageOneBased.clamp(1, totalPages);
  final Set<int> targets = <int>{safeCenter};
  for (int offset = 1; offset <= neighborCount; offset++) {
    final int prev = safeCenter - offset;
    final int next = safeCenter + offset;
    if (prev >= 1) {
      targets.add(prev);
    }
    if (next <= totalPages) {
      targets.add(next);
    }
  }
  for (final int page in extraPageIndexesOneBased) {
    if (page >= 1 && page <= totalPages) {
      targets.add(page);
    }
  }
  return targets;
}

String readerPrefetchCacheKey(String comicId, int archivePageIndex) =>
    '$comicId:$archivePageIndex';

Map<String, Uint8List> evictPrefetchOutsideWindow({
  required Map<String, Uint8List> cache,
  required String comicId,
  required Set<int> keepPagesOneBased,
  required int maxEntriesPerComic,
}) {
  final Set<String> keepKeys = keepPagesOneBased
      .map((int page) => readerPrefetchCacheKey(comicId, page - 1))
      .toSet();
  final Map<String, Uint8List> comicEntries = Map<String, Uint8List>.fromEntries(
    cache.entries.where(
      (MapEntry<String, Uint8List> entry) =>
          entry.key.startsWith('$comicId:') && keepKeys.contains(entry.key),
    ),
  );
  if (comicEntries.length <= maxEntriesPerComic) {
    return <String, Uint8List>{
      ...Map<String, Uint8List>.fromEntries(
        cache.entries.where(
          (MapEntry<String, Uint8List> entry) => !entry.key.startsWith('$comicId:'),
        ),
      ),
      ...comicEntries,
    };
  }
  final List<MapEntry<String, Uint8List>> sorted = comicEntries.entries.toList()
    ..sort((MapEntry<String, Uint8List> a, MapEntry<String, Uint8List> b) {
      final int pageA = int.parse(a.key.split(':').last);
      final int pageB = int.parse(b.key.split(':').last);
      return pageA.compareTo(pageB);
    });
  final Map<String, Uint8List> trimmed = Map<String, Uint8List>.fromEntries(
    sorted.take(maxEntriesPerComic),
  );
  return <String, Uint8List>{
    ...Map<String, Uint8List>.fromEntries(
      cache.entries.where(
        (MapEntry<String, Uint8List> entry) => !entry.key.startsWith('$comicId:'),
      ),
    ),
    ...trimmed,
  };
}
