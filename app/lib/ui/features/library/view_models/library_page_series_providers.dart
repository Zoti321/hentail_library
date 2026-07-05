import 'package:flutter/foundation.dart';
import 'package:hentai_library/domain/models/entity/comic/series.dart';

/// 搜索页等场景复用的系列列表视图 DTO（数据来自 Rust search API）。
@immutable
class LibrarySeriesViewData {
  const LibrarySeriesViewData({
    required this.headerTotalSeriesWithItemsCount,
    required this.seriesWithItemsCount,
    required this.filteredSeries,
  });
  final int headerTotalSeriesWithItemsCount;
  final int seriesWithItemsCount;
  final List<Series> filteredSeries;
}
