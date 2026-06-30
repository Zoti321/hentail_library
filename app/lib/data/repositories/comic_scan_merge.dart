import 'package:hentai_library/domain/models/entity/comic/comic.dart';

/// 保留漫画扫描合并：更新 path/type，并按规则合并 [Comic.pageCount]。
Comic mergeKeptScanWithExisting(Comic scanned, Comic existing) {
  final bool sourceChanged =
      existing.path != scanned.path ||
      existing.resourceType != scanned.resourceType;
  final int? pageCount;
  if (sourceChanged) {
    pageCount = scanned.pageCount;
  } else if (existing.pageCount == null) {
    pageCount = scanned.pageCount;
  } else {
    pageCount = existing.pageCount;
  }
  return existing.copyWith(
    path: scanned.path,
    resourceType: scanned.resourceType,
    pageCount: pageCount,
  );
}
