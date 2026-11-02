/// 阅读进度写入与恢复（read_session 等跨 feature 消费）。
///
/// Token：[readingHistoryCommandPortProvider]（`shared/di/reading_history_providers.dart`）。
abstract class ReadingHistoryCommandPort {
  Future<void> recordReading({
    required String comicId,
    required String title,
    required DateTime lastReadTime,
    required int pageIndex,
  });

  /// 1-based 页码；无记录时为 null。
  Future<int?> readResumePageIndex(String comicId);
}
