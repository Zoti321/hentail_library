import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/domain/library/comic_list_query.dart';
import 'package:hentai_library/domain/models/entity/comic/comic.dart';
import 'package:hentai_library/domain/models/entity/comic/series.dart';
import 'package:hentai_library/domain/models/value_objects/page_request.dart';
import 'package:hentai_library/domain/models/value_objects/paged_result.dart';
import 'package:hentai_library/ui/features/library/view_models/library_query_intent.dart';
import 'package:hentai_library/ui/features/library/view_models/library_query_intent_notifier.dart';
import 'package:hentai_library/ui/features/library/view_models/library_view_settings_providers.dart';
import 'package:hentai_library/ui/features/shell/di/deps.dart';
import 'package:hentai_library/ui/features/shell/state/comic_aggregate_notifier.dart';
import 'package:hentai_library/ui/features/shell/state/series_aggregate_notifier.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'library_page_pagination_providers.g.dart';

const LibraryComicProjection _libraryComicProjection = LibraryComicProjection();

class LibraryComicsPagination {
  const LibraryComicsPagination({
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

/// 筛选/排序/intent 变化时用于重置页码的查询键。
@Riverpod(keepAlive: true)
Object libraryComicsPageQueryKey(Ref ref) {
  final LibraryQueryIntent intent = ref.watch(libraryQueryIntentProvider);
  final LibraryViewSettings viewSettings = ref.watch(
    libraryViewSettingsProvider,
  );
  final Set<String> seriesComicIds = ref.watch(
    libraryComicIdsInAnySeriesProvider,
  );
  return (
    intent.displayTarget,
    intent.sortOption,
    intent.keyword,
    viewSettings.isHealthyMode,
    viewSettings.hideComicsInSeries,
    seriesComicIds.length,
  );
}

@Riverpod(keepAlive: true)
Set<String> libraryComicIdsInAnySeries(Ref ref) {
  final AsyncValue<List<Series>> seriesAsync = ref.watch(allSeriesProvider);
  return seriesAsync.maybeWhen(
    data: (List<Series> list) =>
        _libraryComicProjection.collectComicIdsInAnySeries(list),
    orElse: () => <String>{},
  );
}

@Riverpod(keepAlive: true)
class LibraryComicsPageIndex extends _$LibraryComicsPageIndex {
  @override
  int build() {
    ref.listen<Object>(libraryComicsPageQueryKeyProvider, (
      Object? previous,
      Object next,
    ) {
      if (previous != null) {
        state = 1;
      }
    });
    return 1;
  }

  void setPage(int page) {
    if (page < 1) {
      return;
    }
    state = page;
  }

  void goToFirstPage() {
    state = 1;
  }

  void goToLastPage(int totalPages) {
    if (totalPages <= 0) {
      return;
    }
    state = totalPages;
  }

  void goToPreviousPage() {
    if (state > 1) {
      state = state - 1;
    }
  }

  void goToNextPage(int totalPages) {
    if (totalPages > 0 && state < totalPages) {
      state = state + 1;
    }
  }

  void resetToFirstPage() {
    state = 1;
  }
}

@Riverpod(keepAlive: true)
class LibraryComicsPage extends _$LibraryComicsPage {
  @override
  Future<PagedResult<Comic>> build() async {
    ref.watch(
      comicAggregateProvider.select((ComicAggregateState s) => s.changeGeneration),
    );
    final ComicAggregateState aggregateState = ref.watch(comicAggregateProvider);
    if (aggregateState.streamError != null) {
      throw aggregateState.streamError!;
    }
    final LibraryQueryIntent intent = ref.watch(libraryQueryIntentProvider);
    final LibraryViewSettings viewSettings = ref.watch(
      libraryViewSettingsProvider,
    );
    final Set<String> seriesComicIds = ref.watch(
      libraryComicIdsInAnySeriesProvider,
    );
    final LibraryComicFilter filter = _libraryComicProjection.buildListFilter(
      displayTarget: intent.displayTarget,
      isHealthyMode: viewSettings.isHealthyMode,
      hideComicsInSeries: viewSettings.hideComicsInSeries,
      comicIdsInAnySeries: seriesComicIds,
      keyword: intent.keyword,
    );
    final int page = ref.watch(libraryComicsPageIndexProvider);
    final PagedResult<Comic> result = await ref
        .read(comicRepoProvider)
        .fetchComicsPage(
          request: PageRequest(page: page),
          filter: filter,
          sortOption: intent.sortOption,
        );
    if (result.page != page) {
      ref.read(libraryComicsPageIndexProvider.notifier).setPage(result.page);
    }
    return result;
  }
}

@Riverpod(keepAlive: true)
Future<int> libraryComicTableTotalCount(Ref ref) async {
  ref.watch(comicAggregateProvider.select((ComicAggregateState s) => s.changeGeneration));
  return ref.read(comicRepoProvider).countAll();
}
