import 'package:hentai_library/domain/models/models.dart' as entity;
import 'package:hentai_library/domain/models/value_objects/page_request.dart';
import 'package:hentai_library/domain/models/value_objects/paged_result.dart';

abstract class ReadingHistoryRepository {
  Future<void> recordReading(entity.ReadingHistory history);

  /// 有系列上下文时只写系列历史，否则写漫画历史。
  Future<void> recordProgress(
    entity.ReadingHistory history, {
    entity.SeriesReadingHistory? series,
  });

  Future<entity.ReadingHistory?> getByComicId(String comicId);

  Stream<List<entity.ReadingHistory>> watchAllHistory();

  Future<PagedResult<entity.ReadingHistory>> fetchHistoryPage(
    PageRequest request,
  );

  Future<void> recordSeriesReading(entity.SeriesReadingHistory history);

  Future<entity.SeriesReadingHistory?> getSeriesReadingBySeriesName(
    String seriesName,
  );

  Stream<List<entity.SeriesReadingHistory>> watchAllSeriesReading();

  Future<PagedResult<entity.SeriesReadingHistory>> fetchSeriesHistoryPage(
    PageRequest request,
  );

  Future<void> deleteSeriesReadingBySeriesName(String seriesName);

  Future<void> deleteByComicId(String comicId);

  /// 批量删除阅读历史（如清空漫画库时）。
  Future<void> deleteByComicIds(Iterable<String> comicIds);

  /// 删除 [lastReadComicId] 指向给定漫画的系列阅读行（purge 漫画后避免悬挂 id）。
  Future<void> deleteSeriesReadingByLastReadComicIds(Iterable<String> comicIds);

  Future<void> clearAllHistory();

  Future<void> clearExpiredHistory();
}
