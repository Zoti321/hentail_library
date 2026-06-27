import 'package:hentai_library/data/database/dao/dao.dart';
import 'package:hentai_library/data/database/database.dart' as db;
import 'package:hentai_library/data/mappers/mapping.dart';
import 'package:hentai_library/domain/models/entity/comic/series.dart';
import 'package:hentai_library/domain/models/entity/comic/series_item.dart';
import 'package:hentai_library/domain/models/value_objects/page_request.dart';
import 'package:hentai_library/domain/models/value_objects/paged_result.dart';
import 'package:hentai_library/domain/repositories/series_repository.dart';

class SeriesRepositoryImpl implements SeriesRepository {
  SeriesRepositoryImpl(this._dao, this._searchDao);

  final SeriesDao _dao;
  final SearchDao _searchDao;

  Map<String, List<SeriesItem>> _groupItemsBySeriesName(
    List<db.DbSeriesItem> items,
  ) {
    final Map<String, List<SeriesItem>> groupedItemsBySeries =
        <String, List<SeriesItem>>{};
    for (final db.DbSeriesItem item in items) {
      final List<SeriesItem> grouped = groupedItemsBySeries.putIfAbsent(
        item.seriesName,
        () => <SeriesItem>[],
      );
      grouped.add(item.toEntity());
    }
    return groupedItemsBySeries;
  }

  List<Series> _buildSeriesList(
    List<db.DbSeries> seriesRows,
    Map<String, List<SeriesItem>> groupedItemsBySeries,
  ) {
    return seriesRows
        .map(
          (db.DbSeries series) => Series(
            name: series.name,
            items: groupedItemsBySeries[series.name] ?? const <SeriesItem>[],
          ),
        )
        .toList();
  }

  List<Series> _orderSeriesByNames(
    List<Series> series,
    List<String> orderedNames,
  ) {
    final Map<String, Series> seriesByName = <String, Series>{
      for (final Series series in series) series.name: series,
    };
    final List<Series> ordered = <Series>[];
    for (final String name in orderedNames) {
      final Series? matched = seriesByName[name];
      if (matched != null) {
        ordered.add(matched);
      }
    }
    return ordered;
  }

  Future<Map<String, List<SeriesItem>>> _loadGroupedItemsBySeriesName() async {
    final List<db.DbSeriesItem> allItems = await _dao
        .getAllSeriesItemsOrdered();
    return _groupItemsBySeriesName(allItems);
  }

  Future<List<Series>> _loadSeriesOrderedByNames(
    List<String> seriesNames,
  ) async {
    if (seriesNames.isEmpty) {
      return <Series>[];
    }
    final List<db.DbSeries> seriesRows = await _dao.getSeriesByNames(
      seriesNames,
    );
    final Map<String, List<SeriesItem>> groupedItemsBySeries =
        await _loadGroupedItemsBySeriesName();
    final List<Series> mapped = _buildSeriesList(
      seriesRows,
      groupedItemsBySeries,
    );
    return _orderSeriesByNames(mapped, seriesNames);
  }

  @override
  Stream<List<Series>> watchAll() {
    return _dao.watchAllSeries().asyncMap((rows) async {
      return rows.map((r) => Series(name: r.name, items: const [])).toList();
    });
  }

  @override
  Future<List<Series>> getAll() async {
    final List<db.DbSeries> seriesRows = await _dao.getAllSeries();
    final Map<String, List<SeriesItem>> groupedItemsBySeries =
        await _loadGroupedItemsBySeriesName();
    return _buildSeriesList(seriesRows, groupedItemsBySeries);
  }

  @override
  Future<PagedResult<Series>> fetchPage(PageRequest request) async {
    final int totalCount = await _dao.countAllSeries();
    if (totalCount <= 0) {
      return PagedResult<Series>(
        items: const <Series>[],
        totalCount: 0,
        page: 1,
        pageSize: request.pageSize,
      );
    }
    final int totalPages = (totalCount + request.pageSize - 1) ~/ request.pageSize;
    int effectivePage = request.page;
    if (effectivePage > totalPages) {
      effectivePage = totalPages;
    }
    final int offset = (effectivePage - 1) * request.pageSize;
    final List<db.DbSeries> seriesRows = await _dao.fetchSeriesPage(
      limit: request.pageSize,
      offset: offset,
    );
    final Map<String, List<SeriesItem>> groupedItemsBySeries =
        await _loadGroupedItemsBySeriesName();
    final List<Series> items = _buildSeriesList(
      seriesRows,
      groupedItemsBySeries,
    );
    return PagedResult<Series>(
      items: items,
      totalCount: totalCount,
      page: effectivePage,
      pageSize: request.pageSize,
    );
  }

  @override
  Future<Series?> findByName(String name) async {
    final row = await _dao.findByName(name);
    if (row == null) {
      return null;
    }
    final items = await _dao.getItemsForSeries(name);
    return Series(
      name: row.name,
      items: items.map((db.DbSeriesItem i) => i.toEntity()).toList(),
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
    return _loadSeriesOrderedByNames(seriesNames);
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
    return _loadSeriesOrderedByNames(seriesNames);
  }
}
