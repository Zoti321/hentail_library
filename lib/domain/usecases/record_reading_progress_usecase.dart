import 'package:hentai_library/domain/entity/reading_history.dart';
import 'package:hentai_library/domain/entity/series_reading_history.dart';
import 'package:hentai_library/domain/repository/reading_history_repo.dart';

/// 用例：记录或更新阅读进度（进入阅读页、翻页时调用）。
///
/// - 无系列上下文时：只写入漫画阅读历史。
/// - 有系列上下文时：只写入系列阅读历史，避免与漫画历史重复。
class RecordReadingProgressUseCase {
  final ReadingHistoryRepository _readingHistoryRepository;

  RecordReadingProgressUseCase(this._readingHistoryRepository);

  Future<void> call(
    ReadingHistory history, {
    SeriesReadingHistory? series,
  }) async {
    if (series != null) {
      await _readingHistoryRepository.recordSeriesReading(series);
      return;
    }
    await _readingHistoryRepository.recordReading(history);
  }
}
