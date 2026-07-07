import 'package:hentai_library/domain/models/entity/comic/comic.dart';
import 'package:hentai_library/domain/models/entity/comic/series.dart';
import 'package:hentai_library/ui/features/library/view_models/library_page_snapshot.dart';

/// 漫画 Tab 目录列表状态。
class LibraryComicsCatalogState {
  const LibraryComicsCatalogState({
    required this.items,
    required this.pagination,
    required this.filterQuery,
    required this.hasReceivedFirstEmit,
    required this.isComicTableEmpty,
    this.showPagination = true,
  });

  final List<Comic> items;
  final LibraryPagination pagination;
  final String filterQuery;
  final bool hasReceivedFirstEmit;
  final bool isComicTableEmpty;
  final bool showPagination;

  int get displayedCount => pagination.totalCount;
}

/// 系列 Tab 目录列表状态。
class LibrarySeriesCatalogState {
  const LibrarySeriesCatalogState({
    required this.items,
    required this.pagination,
    required this.filterQuery,
    required this.isSeriesTableEmpty,
    this.showPagination = true,
  });

  final List<Series> items;
  final LibraryPagination pagination;
  final String filterQuery;
  final bool isSeriesTableEmpty;
  final bool showPagination;

  int get displayedCount => pagination.totalCount;
}
