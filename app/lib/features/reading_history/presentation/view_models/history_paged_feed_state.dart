import 'package:hentai_library/features/reading_history/domain/reading_history_section_counts.dart';
import 'package:hentai_library/features/reading_history/presentation/models/history_card_item.dart';

class HistoryPagedFeedState {
  const HistoryPagedFeedState({
    required this.items,
    required this.totalCount,
    required this.sectionCounts,
    required this.loadedPage,
    required this.hasReachedEnd,
    required this.keyword,
    this.isLoadingMore = false,
  });

  final List<HistoryCardItem> items;
  final int totalCount;
  final ReadingHistorySectionCounts sectionCounts;
  final int loadedPage;
  final bool hasReachedEnd;
  final String keyword;
  final bool isLoadingMore;

  HistoryPagedFeedState copyWith({
    List<HistoryCardItem>? items,
    int? totalCount,
    ReadingHistorySectionCounts? sectionCounts,
    int? loadedPage,
    bool? hasReachedEnd,
    String? keyword,
    bool? isLoadingMore,
  }) {
    return HistoryPagedFeedState(
      items: items ?? this.items,
      totalCount: totalCount ?? this.totalCount,
      sectionCounts: sectionCounts ?? this.sectionCounts,
      loadedPage: loadedPage ?? this.loadedPage,
      hasReachedEnd: hasReachedEnd ?? this.hasReachedEnd,
      keyword: keyword ?? this.keyword,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }
}
