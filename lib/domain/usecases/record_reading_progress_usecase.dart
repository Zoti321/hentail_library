import 'package:hentai_library/domain/entity/reading_history.dart';
import 'package:hentai_library/domain/entity/series_reading_history.dart';
import 'package:hentai_library/domain/repository/reading_history_repo.dart';

/// 用例：记录或更新阅读进度（进入阅读页、翻页时调用）。
class RecordReadingProgressUseCase {
  final ReadingHistoryRepository _readingHistoryRepository;

  RecordReadingProgressUseCase(this._readingHistoryRepository);

  Future<void> call(
    ReadingHistory history, {
    SeriesReadingHistory? series,
  }) async {
    await _readingHistoryRepository.recordReading(history);
    if (series != null) {
      await _readingHistoryRepository.recordSeriesReading(series);
    }
  }
}
