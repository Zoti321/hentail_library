import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/domain/models/entity/comic/comic.dart';
import 'package:hentai_library/domain/models/entity/reading_history.dart'
    as entity;
import 'package:hentai_library/ui/features/shell/state/comic_aggregate_notifier.dart';
import 'package:hentai_library/ui/core/dto/history_grid_item_dto.dart';
import 'package:hentai_library/ui/features/shell/di/deps.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'history_page_notifier.g.dart';

const int _kHistoryContinueReadingVisibleCount = 10;

class HistoryFeedViewData {
  const HistoryFeedViewData({
    required this.isLoading,
    required this.hasError,
    required this.totalCount,
    required this.mergedItems,
    required this.continueReadingItems,
  });
  final bool isLoading;
  final bool hasError;
  final int totalCount;
  final List<HistoryGridItemDto> mergedItems;
  final List<HistoryGridItemDto> continueReadingItems;
}

@Riverpod(keepAlive: true)
Stream<List<entity.ReadingHistory>> readingHistoryStream(Ref ref) {
  return ref.watch(readingHistoryRepoProvider).watchAllHistory();
}

@Riverpod(keepAlive: true)
Future<Map<String, Comic>> historyComicsById(Ref ref) async {
  ref.watch(
    comicAggregateProvider.select(
      (ComicAggregateState s) => s.changeGeneration,
    ),
  );
  final List<Comic> comics = await ref.read(comicRepoProvider).getAll();
  return <String, Comic>{
    for (final Comic comic in comics) comic.comicId: comic,
  };
}

@Riverpod(keepAlive: true)
List<HistoryGridItemDto> mergedHistoryGridItems(Ref ref) {
  final List<entity.ReadingHistory> comics = ref
      .watch(readingHistoryStreamProvider)
      .maybeWhen(
        data: (data) => data,
        orElse: () => const <entity.ReadingHistory>[],
      );
  final List<HistoryGridItemDto> merged = comics
      .map(
        (entity.ReadingHistory history) => HistoryGridItemDto(
          id: 'comic:${history.comicId}',
          title: history.title,
          lastReadTime: history.lastReadTime,
          coverComicId: history.comicId,
          comicId: history.comicId,
          pageIndex: history.pageIndex,
        ),
      )
      .toList(growable: false);
  merged.sort((a, b) => b.lastReadTime.compareTo(a.lastReadTime));
  return merged;
}

@Riverpod(keepAlive: true)
HistoryFeedViewData historyFeedView(Ref ref) {
  final AsyncValue<List<entity.ReadingHistory>> comicsAsync = ref.watch(
    readingHistoryStreamProvider,
  );
  final bool isLoading = comicsAsync.isLoading;
  final bool hasError = comicsAsync.hasError;
  final List<HistoryGridItemDto> visibleItems = ref.watch(
    historyVisibleGridItemsProvider,
  );
  final int totalCount = visibleItems.length;
  final List<HistoryGridItemDto> continueReadingItems = visibleItems
      .take(_kHistoryContinueReadingVisibleCount)
      .toList(growable: false);
  return HistoryFeedViewData(
    isLoading: isLoading,
    hasError: hasError,
    totalCount: totalCount,
    mergedItems: visibleItems,
    continueReadingItems: continueReadingItems,
  );
}

/// Desktop history page search query. Auto-dispose clears when the page is left.
class HistorySearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';

  void setQuery(String value) {
    state = value;
  }
}

final historySearchQueryProvider =
    NotifierProvider.autoDispose<HistorySearchQueryNotifier, String>(
      HistorySearchQueryNotifier.new,
    );

final Provider<List<HistoryGridItemDto>> historyVisibleGridItemsProvider =
    Provider<List<HistoryGridItemDto>>((Ref ref) {
      final List<HistoryGridItemDto> mergedItems = ref.watch(
        mergedHistoryGridItemsProvider,
      );
      final String query = ref.watch(historySearchQueryProvider);
      final String normalizedQuery = query.trim().toLowerCase();
      if (normalizedQuery.isEmpty) {
        return mergedItems;
      }
      return mergedItems
          .where(
            (HistoryGridItemDto item) =>
                item.title.toLowerCase().contains(normalizedQuery),
          )
          .toList(growable: false);
    });
