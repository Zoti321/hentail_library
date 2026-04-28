import 'package:hentai_library/model/entity/reading_history.dart';
import 'package:hentai_library/model/entity/series_reading_history.dart';

abstract class ReadingHistoryRepository {
  Future<void> recordReading(ReadingHistory history);

  Future<ReadingHistory?> getByComicId(String comicId);

  Stream<List<ReadingHistory>> watchAllHistory();

  Future<void> recordSeriesReading(SeriesReadingHistory history);

  Future<SeriesReadingHistory?> getSeriesReadingBySeriesName(String seriesName);

  Stream<List<SeriesReadingHistory>> watchAllSeriesReading();

  Future<void> deleteSeriesReadingBySeriesName(String seriesName);

  Future<void> deleteByComicId(String comicId);

  /// 批量删除阅读历史（如清空漫画库时）。
  Future<void> deleteByComicIds(Iterable<String> comicIds);

  /// 删除 [lastReadComicId] 指向给定漫画的系列阅读行（purge 漫画后避免悬挂 id）。
  Future<void> deleteSeriesReadingByLastReadComicIds(Iterable<String> comicIds);

  Future<void> clearAllHistory();

  Future<void> clearExpiredHistory();
}
