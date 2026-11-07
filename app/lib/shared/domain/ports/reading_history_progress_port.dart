/// 库浏览封面进度（comicId → 1-based pageIndex）。
///
/// Token：[readingHistoryProgressPortProvider]（`shared/di/reading_history_providers.dart`）。
abstract class ReadingHistoryProgressPort {
  Stream<Map<String, int>> watchReadPageIndexes();
}
