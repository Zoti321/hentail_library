import 'package:hentai_library/domain/models/entity/comic/comic.dart';
import 'package:hentai_library/domain/models/entity/comic/series.dart';
import 'package:hentai_library/domain/models/enums.dart';

class LibraryPagination {
  const LibraryPagination({
    required this.page,
    required this.totalPages,
    required this.totalCount,
    required this.isLoading,
  });

  final int page;
  final int totalPages;
  final int totalCount;
  final bool isLoading;
}

/// 库页渲染快照：漫画/系列当前页、分页与 intent 元数据。
class LibraryPageSnapshot {
  const LibraryPageSnapshot({
    required this.comics,
    required this.comicsPagination,
    required this.series,
    required this.seriesPagination,
    required this.displayedComicCount,
    required this.displayedSeriesCount,
    required this.displayTarget,
    required this.filterQuery,
    required this.hasReceivedFirstEmit,
    required this.isComicTableEmpty,
    this.showPagination = true,
  });

  final List<Comic> comics;
  final LibraryPagination comicsPagination;
  final List<Series> series;
  final LibraryPagination seriesPagination;
  final int displayedComicCount;
  final int displayedSeriesCount;
  final LibraryDisplayTarget displayTarget;
  final String filterQuery;
  final bool hasReceivedFirstEmit;
  final bool isComicTableEmpty;
  final bool showPagination;
}

/// 兼容搜索页等仍引用旧名称的调用方。
typedef LibraryPageViewModel = LibraryPageSnapshot;

/// 兼容旧分页类型名。
typedef LibraryComicsPagination = LibraryPagination;
