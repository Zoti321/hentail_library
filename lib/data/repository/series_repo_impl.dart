import 'package:hentai_library/data/resources/local/database/dao.dart';
import 'package:hentai_library/data/resources/local/database/database.dart'
    as db;
import 'package:hentai_library/domain/entity/comic/series.dart' as entity;
import 'package:hentai_library/domain/entity/comic/series_item.dart' as entity;
import 'package:hentai_library/domain/repository/series_repo.dart';

class SeriesRepositoryImpl implements SeriesRepository {
  final SeriesDao _dao;

  SeriesRepositoryImpl(this._dao);

  @override
  Stream<List<entity.Series>> watchAll() {
    return _dao.watchAllSeries().asyncMap((rows) async {
      // 目前只映射 series 基本信息；items 由 findById/getAll 单独查询。
      return rows
          .map((r) => entity.Series(name: r.name, items: const []))
          .toList();
    });
  }

  @override
  Future<List<entity.Series>> getAll() async {
    final List<db.DbSeries> seriesRows = await _dao.getAllSeries();
    final List<db.DbSeriesItem> allItems = await _dao
        .getAllSeriesItemsOrdered();
    final Map<String, List<entity.SeriesItem>> groupedItemsBySeries =
        <String, List<entity.SeriesItem>>{};
    for (final db.DbSeriesItem item in allItems) {
      final List<entity.SeriesItem> grouped = groupedItemsBySeries.putIfAbsent(
        item.seriesName,
        () => <entity.SeriesItem>[],
      );
      grouped.add(
        entity.SeriesItem(comicId: item.comicId, order: item.sortOrder),
      );
    }
    return seriesRows.map((db.DbSeries series) {
      return entity.Series(
        name: series.name,
        items: groupedItemsBySeries[series.name] ?? const <entity.SeriesItem>[],
      );
    }).toList();
  }

  @override
  Future<entity.Series?> findByName(String name) async {
    final row = await _dao.findByName(name);
    if (row == null) return null;
    final items = await _dao.getItemsForSeries(name);
    return entity.Series(
      name: row.name,
      items: items
          .map((i) => entity.SeriesItem(comicId: i.comicId, order: i.sortOrder))
          .toList(),
    );
  }

  @override
  Future<void> create(String name) async {
    await _dao.createSeries(db.SeriesTableCompanion.insert(name: name));
  }

  @override
  Future<void> rename({required String name, required String newName}) async {
    await _dao.renameSeries(name: name, newName: newName);
  }

  @override
  Future<void> delete(String seriesId) async {
    await _dao.deleteSeries(seriesId);
  }

  @override
  Future<void> assignComicExclusive({
    required String comicId,
    required String targetSeriesName,
    required int order,
  }) async {
    await _dao.assignComicExclusive(
      comicId: comicId,
      targetSeriesName: targetSeriesName,
      sortOrder: order,
    );
  }

  /// 从系列中移除单个漫画
  @override
  Future<void> removeComic(String comicId) async {
    await _dao.removeComic(comicId);
  }

  @override
  Future<void> removeComicsFromSeries(Iterable<String> comicIds) async {
    await _dao.removeComicsFromSeries(comicIds);
  }

  @override
  Future<void> removeOrphanSeriesItems() async {
    await _dao.removeOrphanSeriesItems();
  }

  @override
  Future<void> setSeriesItemsOrder(
    String seriesName,
    List<entity.SeriesItem> orderedItems,
  ) async {
    await _dao.transaction(() async {
      for (int i = 0; i < orderedItems.length; i++) {
        await _dao.updateSeriesItemSortOrder(
          seriesName: seriesName,
          comicId: orderedItems[i].comicId,
          sortOrder: i,
        );
      }
    });
  }
}
