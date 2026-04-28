import 'package:hentai_library/model/entity/comic/comic.dart';
import 'package:hentai_library/model/entity/comic/series.dart';
import 'package:hentai_library/module/comic_list_query/comic_list_query.dart';

/// 领域查询对象：封装“系列筛选 + 排序”规则，避免 UI/Provider 出现过程式循环细节。
class LibrarySeriesQueryResult {
  const LibrarySeriesQueryResult({
    required this.headerTotalSeriesWithItemsCount,
    required this.seriesWithItemsCount,
    required this.filteredSeries,
  });
  final int headerTotalSeriesWithItemsCount;
  final int seriesWithItemsCount;
  final List<Series> filteredSeries;
}

class LibrarySeriesQuery {
  const LibrarySeriesQuery({
    required this.showR18,
    required this.query,
    required this.sortOption,
    required this.comicsById,
  });
  final bool showR18;
  final String query;
  final LibraryComicSortOption sortOption;
  final Map<String, Comic> comicsById;
  LibrarySeriesQueryResult apply(List<Series> source) {
    final String lowerQuery = query.trim().toLowerCase();
    final List<Series> availableSeries = source
        .where((Series series) => series.items.isNotEmpty)
        .toList();
    final int headerTotalWithItems = availableSeries.length;
    final List<Series> visibleSeries = availableSeries
        .where(_canDisplaySeries)
        .toList();
    final List<Series> filteredSeries = visibleSeries
        .where(
          (Series series) =>
              lowerQuery.isEmpty ||
              series.name.toLowerCase().contains(lowerQuery),
        )
        .toList();
    final List<Series> sortedSeries = _applySort(filteredSeries);
    return LibrarySeriesQueryResult(
      headerTotalSeriesWithItemsCount: headerTotalWithItems,
      seriesWithItemsCount: visibleSeries.length,
      filteredSeries: sortedSeries,
    );
  }

  bool _canDisplaySeries(Series series) {
    if (showR18) {
      return true;
    }
    return !series.hasR18Comic(comicsById: comicsById);
  }

  List<Series> _applySort(List<Series> source) {
    final List<Series> sorted = List<Series>.from(source);
    switch (sortOption.field) {
      case LibraryComicSortField.title:
        sorted.sort((Series a, Series b) {
          final int result = a.name.compareTo(b.name);
          return sortOption.descending ? -result : result;
        });
        return sorted;
    }
  }
}
