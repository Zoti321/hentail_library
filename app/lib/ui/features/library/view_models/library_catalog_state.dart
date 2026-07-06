import 'package:hentai_library/domain/models/entity/comic/comic.dart';
import 'package:hentai_library/domain/models/entity/comic/series.dart';
import 'package:hentai_library/ui/features/library/view_models/library_page_snapshot.dart';

/// ?? Tab ???????
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

/// ?? Tab ???????
class LibrarySeriesCatalogState {
  const LibrarySeriesCatalogState({
    required this.items,
    required this.pagination,
    required this.filterQuery,
    this.showPagination = true,
  });

  final List<Series> items;
  final LibraryPagination pagination;
  final String filterQuery;
  final bool showPagination;

  int get displayedCount => pagination.totalCount;
}
