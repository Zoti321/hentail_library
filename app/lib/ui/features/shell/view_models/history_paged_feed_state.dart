import 'package:hentai_library/ui/core/dto/history_grid_item.dart';

class HistoryPagedFeedState {
  const HistoryPagedFeedState({
    required this.items,
    required this.totalCount,
    required this.loadedPage,
    required this.hasReachedEnd,
    required this.keyword,
    this.isLoadingMore = false,
  });

  final List<HistoryGridItem> items;
  final int totalCount;
  final int loadedPage;
  final bool hasReachedEnd;
  final String keyword;
  final bool isLoadingMore;

  HistoryPagedFeedState copyWith({
    List<HistoryGridItem>? items,
    int? totalCount,
    int? loadedPage,
    bool? hasReachedEnd,
    String? keyword,
    bool? isLoadingMore,
  }) {
    return HistoryPagedFeedState(
      items: items ?? this.items,
      totalCount: totalCount ?? this.totalCount,
      loadedPage: loadedPage ?? this.loadedPage,
      hasReachedEnd: hasReachedEnd ?? this.hasReachedEnd,
      keyword: keyword ?? this.keyword,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }
}
