import 'package:hentai_library/features/library_browse/presentation/browse/models/comic_browse_vo.dart';
import 'package:hentai_library/features/library_browse/presentation/browse/models/series_browse_vo.dart';
import 'package:hentai_library/features/library_browse/presentation/browse/view_models/library_page_snapshot.dart';

/// 漫画 Tab 目录列表状态（持 [ComicBrowseVO]，不持完整 Comic 聚合）。
class LibraryComicsCatalogState {
  const LibraryComicsCatalogState({
    required this.items,
    required this.pagination,
    required this.filterQuery,
    required this.hasReceivedFirstEmit,
    required this.isComicTableEmpty,
    this.showPagination = true,
  });

  final List<ComicBrowseVO> items;
  final LibraryPagination pagination;
  final String filterQuery;
  final bool hasReceivedFirstEmit;
  final bool isComicTableEmpty;
  final bool showPagination;

  int get displayedCount => pagination.totalCount;
}

/// 系列 Tab 目录列表状态（持 [SeriesBrowseVO]，不持完整 Series 聚合）。
class LibrarySeriesCatalogState {
  const LibrarySeriesCatalogState({
    required this.items,
    required this.pagination,
    required this.filterQuery,
    required this.isSeriesTableEmpty,
    this.showPagination = true,
  });

  final List<SeriesBrowseVO> items;
  final LibraryPagination pagination;
  final String filterQuery;
  final bool isSeriesTableEmpty;
  final bool showPagination;

  int get displayedCount => pagination.totalCount;
}
