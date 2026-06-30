import 'package:hentai_library/domain/models/entity/comic/comic.dart';
import 'package:hentai_library/domain/models/entity/reading_history.dart';
import 'package:hentai_library/domain/models/entity/series_reading_history.dart';
import 'package:hentai_library/domain/use_cases/record_reading_progress_usecase.dart';

/// Standalone read / Series read 进度写入规则（与 [RecordReadingProgressUseCase] 对齐）。
class SaveReadSessionProgressUseCase {
  SaveReadSessionProgressUseCase(this._recordReadingProgress);

  final RecordReadingProgressUseCase _recordReadingProgress;

  Future<void> call({
    required Comic comic,
    required int pageIndex,
    required bool isSeriesMode,
    String? seriesName,
  }) async {
    final DateTime now = DateTime.now();
    final String? validSeriesName = isSeriesMode ? seriesName : null;
    final SeriesReadingHistory? series =
        validSeriesName != null && validSeriesName.isNotEmpty
        ? SeriesReadingHistory(
            seriesName: validSeriesName,
            lastReadComicId: comic.comicId,
            lastReadTime: now,
            pageIndex: pageIndex,
          )
        : null;
    await _recordReadingProgress.call(
      ReadingHistory(
        comicId: comic.comicId,
        title: comic.title,
        lastReadTime: now,
        pageIndex: pageIndex,
      ),
      series: series,
    );
  }
}
