import 'package:hentai_library/core/errors/app_exception.dart';
import 'package:hentai_library/core/logging/app_log.dart';
import 'package:hentai_library/data/adapters/frb_call_guard.dart';
import 'package:hentai_library/data/adapters/history_frb_mapper.dart';
import 'package:hentai_library/domain/models/entity/series_reading_history.dart';
import 'package:hentai_library/domain/repositories/series_reading_history_repository.dart';
import 'package:hentai_library/src/rust/api/history.dart' as rust;

class SeriesReadingHistoryRepositoryImpl
    implements SeriesReadingHistoryRepository {
  const SeriesReadingHistoryRepositoryImpl();

  @override
  Future<void> recordSeriesReading(SeriesReadingHistory history) async {
    try {
      guardFrbSync(
        () => rust.recordSeriesReadingFrb(
          history: toSeriesReadingHistoryDto(history),
        ),
        fallbackMessage: '记录系列阅读进度失败',
      );
    } catch (e, st) {
      logError(
        AppLog.dataRepo('series_reading_history'),
        '记录系列阅读进度失败，seriesId=${history.seriesId}',
        e,
        st,
      );
      if (e is AppException) {
        rethrow;
      }
      throw AppException('记录系列阅读进度失败', cause: e, stackTrace: st);
    }
  }

  @override
  Future<SeriesReadingHistory?> getBySeriesId(String seriesId) async {
    final rust.SeriesReadingHistoryDto? row = guardFrbSync(
      () => rust.getSeriesReadingBySeriesIdFrb(seriesId: seriesId),
      fallbackMessage: '读取系列阅读进度失败',
    );
    return row == null ? null : mapSeriesReadingHistoryDto(row);
  }
}
