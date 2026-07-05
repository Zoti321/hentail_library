import 'package:hentai_library/domain/models/entity/series_reading_history.dart';

abstract class SeriesReadingHistoryRepository {
  Future<void> recordSeriesReading(SeriesReadingHistory history);

  Future<SeriesReadingHistory?> getBySeriesId(String seriesId);
}
