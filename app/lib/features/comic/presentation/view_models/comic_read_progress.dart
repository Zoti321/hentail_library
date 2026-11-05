import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/shared/di/reading_history_providers.dart';

/// 阅读历史中每部漫画的当前页（1 基，与阅读器 `pageIndex` 一致）。
///
/// 仅包含有阅读记录的漫画；随阅读历史变化实时刷新。
final StreamProvider<Map<String, int>> comicReadPageIndexByIdProvider =
    StreamProvider<Map<String, int>>((Ref ref) {
      return ref
          .watch(readingHistoryProgressPortProvider)
          .watchReadPageIndexes();
    });

/// 由当前页和总页数计算封面进度条比例，范围 0–1；无记录或总页数无效时为 null。
double? comicReadProgressFor({
  required int? pageIndex,
  required int pageCount,
}) {
  if (pageIndex == null || pageCount <= 0) {
    return null;
  }
  return (pageIndex / pageCount).clamp(0.0, 1.0);
}
