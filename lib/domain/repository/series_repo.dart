import 'package:hentai_library/domain/entity/comic/series.dart';
import 'package:hentai_library/domain/entity/comic/series_item.dart';

/// Series 仓储：系列独立聚合，维护漫画归属与顺序。
abstract class SeriesRepository {
  Stream<List<Series>> watchAll();

  Future<List<Series>> getAll();

  Future<Series?> findByName(String name);

  Future<void> create(String name);

  Future<void> rename({required String name, required String newName});

  Future<void> delete(String name);

  /// 排他归属：保证同一 comicId 只能属于一个系列。
  Future<void> assignComicExclusive({
    required String comicId,
    required String targetSeriesName,
    required int order,
  });

  Future<void> removeComic(String comicId);

  /// 批量移除系列中的漫画归属（无 FK 指向 comics，清空库时需单独清理）。
  Future<void> removeComicsFromSeries(Iterable<String> comicIds);

  /// 按 [orderedItems] 顺序将 [seriesName] 下各条目的顺序写为 0..length-1。
  Future<void> setSeriesItemsOrder(String seriesName, List<SeriesItem> orderedItems);
}
