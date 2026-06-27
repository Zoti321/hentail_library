import 'package:hentai_library/data/database/dao/dao.dart';
import 'package:hentai_library/data/database/database.dart' as db;
import 'package:hentai_library/domain/models/entity/comic/series.dart';
import 'package:hentai_library/domain/models/entity/comic/series_item.dart';
import 'package:hentai_library/domain/repositories/series_repository.dart';

class SeriesRepositoryImpl implements SeriesRepository {
  SeriesRepositoryImpl(this._dao, this._searchDao);

  final SeriesDao _dao;
  final SearchDao _searchDao;

  @override
  Stream<List<Series>> watchAll() {
    return _dao.watchAllSeries().asyncMap((rows) async {
      return rows.map((r) => Series(name: r.name, items: const [])).toList();
    });
  }

  @override
  Future<List<Series>> getAll() async {
    final List<db.DbSeries> seriesRows = await _dao.getAllSeries();
    final List<db.DbSeriesItem> allItems = await _dao
        .getAllSeriesItemsOrdered();
    final Map<String, List<SeriesItem>> groupedItemsBySeries =
        <String, List<SeriesItem>>{};
    for (final db.DbSeriesItem item in allItems) {
      final List<SeriesItem> grouped = groupedItemsBySeries.putIfAbsent(
        item.seriesName,
        () => <SeriesItem>[],
      );
      grouped.add(SeriesItem(comicId: item.comicId, order: item.sortOrder));
    }
    return seriesRows.map((db.DbSeries series) {
      return Series(
        name: series.name,
        items: groupedItemsBySeries[series.name] ?? const <SeriesItem>[],
      );
    }).toList();
  }

  @override
  Future<Series?> findByName(String name) async {
    final row = await _dao.findByName(name);
    if (row == null) return null;
    final items = await _dao.getItemsForSeries(name);
    return Series(
      name: row.name,
      items: items
          .map((i) => SeriesItem(comicId: i.comicId, order: i.sortOrder))
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
  Future<void> delete(String name) async {
    await _dao.deleteSeries(name);
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
    List<SeriesItem> orderedItems,
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

  @override
  Future<List<Series>> searchByKeyword(String keyword) async {
    final List<String> seriesNames = await _searchDao
        .searchSeriesNamesByKeyword(keyword);
    if (seriesNames.isEmpty) {
      return <Series>[];
    }
    final List<db.DbSeries> seriesRows = await _dao.getSeriesByNames(
      seriesNames,
    );
    final List<db.DbSeriesItem> allItems = await _dao
        .getAllSeriesItemsOrdered();
    final Map<String, List<SeriesItem>> groupedItemsBySeries =
        <String, List<SeriesItem>>{};
    for (final db.DbSeriesItem item in allItems) {
      final List<SeriesItem> grouped = groupedItemsBySeries.putIfAbsent(
        item.seriesName,
        () => <SeriesItem>[],
      );
      grouped.add(SeriesItem(comicId: item.comicId, order: item.sortOrder));
    }
    final Map<String, Series> mapped = <String, Series>{
      for (final db.DbSeries series in seriesRows)
        series.name: Series(
          name: series.name,
          items: groupedItemsBySeries[series.name] ?? const <SeriesItem>[],
        ),
    };
    final List<Series> ordered = <Series>[];
    for (final String name in seriesNames) {
      final Series? series = mapped[name];
      if (series != null) {
        ordered.add(series);
      }
    }
    return ordered;
  }

  @override
  Future<List<Series>> searchByTagExpression({
    required Set<String> mustInclude,
    required Set<String> optionalOr,
    required Set<String> mustExclude,
  }) async {
    final List<String> seriesNames = await _searchDao
        .searchSeriesNamesByTagExpression(
          mustInclude: mustInclude,
          optionalOr: optionalOr,
          mustExclude: mustExclude,
        );
    if (seriesNames.isEmpty) {
      return <Series>[];
    }
    final List<db.DbSeries> seriesRows = await _dao.getSeriesByNames(
      seriesNames,
    );
    final List<db.DbSeriesItem> allItems = await _dao
        .getAllSeriesItemsOrdered();
    final Map<String, List<SeriesItem>> groupedItemsBySeries =
        <String, List<SeriesItem>>{};
    for (final db.DbSeriesItem item in allItems) {
      final List<SeriesItem> grouped = groupedItemsBySeries.putIfAbsent(
        item.seriesName,
        () => <SeriesItem>[],
      );
      grouped.add(SeriesItem(comicId: item.comicId, order: item.sortOrder));
    }
    final Map<String, Series> mapped = <String, Series>{
      for (final db.DbSeries series in seriesRows)
        series.name: Series(
          name: series.name,
          items: groupedItemsBySeries[series.name] ?? const <SeriesItem>[],
        ),
    };
    final List<Series> ordered = <Series>[];
    for (final String name in seriesNames) {
      final Series? series = mapped[name];
      if (series != null) {
        ordered.add(series);
      }
    }
    return ordered;
  }
}
