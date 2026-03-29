import 'package:hentai_library/domain/entity/comic/library_comic.dart';

/// 扫描结果与库内现有 [comicId] 集合的差分（仅 ID 层面）。
typedef LibraryComicScanIdDiff = ({
  Set<String> removedIds,
  Set<String> addedIds,
  Set<String> keptIds,
});

/// 对扫描列表按 [LibraryComic.comicId] 去重，后者覆盖前者。
Map<String, LibraryComic> dedupeScannedByComicId(List<LibraryComic> scanned) {
  final map = <String, LibraryComic>{};
  for (final c in scanned) {
    map[c.comicId] = c;
  }
  return map;
}

/// 基于现有 ID 集合与本次扫描 ID 集合计算 removed / added / kept。
LibraryComicScanIdDiff computeLibraryComicScanIdDiff({
  required Set<String> existingIds,
  required Set<String> scannedIds,
}) {
  return (
    removedIds: existingIds.difference(scannedIds),
    addedIds: scannedIds.difference(existingIds),
    keptIds: existingIds.intersection(scannedIds),
  );
}

/// [kept] 条目：用扫描结果更新路径与资源类型，保留库内已有标题、作者、分级与标签。
LibraryComic mergeKeptScanWithExisting(LibraryComic scanned, LibraryComic existing) {
  return existing.copyWith(
    path: scanned.path,
    resourceType: scanned.resourceType,
  );
}
