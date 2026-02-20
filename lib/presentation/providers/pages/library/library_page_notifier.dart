import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hentai_library/domain/entity/comic/comic.dart';
import 'package:hentai_library/domain/entity/comic/series.dart';
import 'package:hentai_library/domain/entity/comic/series_item.dart';
import 'package:hentai_library/domain/util/enums.dart';
import 'package:hentai_library/domain/util/comic_query.dart';
import 'package:hentai_library/domain/value_objects/library_comic_filter.dart';
import 'package:hentai_library/domain/value_objects/library_display_target.dart';
import 'package:hentai_library/domain/value_objects/library_comic_sort_option.dart';
import 'package:hentai_library/presentation/providers/aggregates/comic_aggregate_notifier.dart';
import 'package:hentai_library/presentation/providers/aggregates/series_aggregate_notifier.dart';
import 'package:hentai_library/presentation/providers/pages/settings/settings_notifier.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:hentai_library/domain/entity/entities.dart' show AppSetting;

part 'library_page_notifier.freezed.dart';
part 'library_page_notifier.g.dart';

List<Comic> applyLibraryDisplayedComicsQuery(LibraryPageState state) {
  return ComicQuery(
    filter: state.effectiveFilter,
    sortOption: state.effectiveSortOption,
  ).apply(state.rawList);
}

AsyncValue<List<Comic>> buildLibraryComicsAsyncValue(LibraryPageState state) {
  if (state.streamError != null) {
    return AsyncValue.error(state.streamError!, StackTrace.current);
  }
  if (!state.hasReceivedFirstEmit) {
    return const AsyncValue.loading();
  }
  return AsyncValue.data(applyLibraryDisplayedComicsQuery(state));
}

List<Series> applyLibraryDisplayedSeriesSort({
  required List<Series> seriesList,
  required LibraryComicSortOption sortOption,
}) {
  final List<Series> sorted = List<Series>.from(seriesList);
  switch (sortOption.field) {
    case LibraryComicSortField.title:
      sorted.sort((Series a, Series b) {
        final int result = a.name.compareTo(b.name);
        return sortOption.descending ? -result : result;
      });
      return sorted;
  }
}

@immutable
class _LibraryComicsStreamInput {
  const _LibraryComicsStreamInput({
    required this.rawList,
    required this.filter,
    required this.sortOption,
    required this.hasReceivedFirstEmit,
    required this.streamError,
  });
  final List<Comic> rawList;
  final LibraryComicFilter filter;
  final LibraryComicSortOption sortOption;
  final bool hasReceivedFirstEmit;
  final Object? streamError;
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is _LibraryComicsStreamInput &&
        identical(rawList, other.rawList) &&
        filter == other.filter &&
        sortOption == other.sortOption &&
        hasReceivedFirstEmit == other.hasReceivedFirstEmit &&
        streamError == other.streamError;
  }

  @override
  int get hashCode => Object.hash(
    rawList,
    filter,
    sortOption,
    hasReceivedFirstEmit,
    streamError,
  );
}

@freezed
abstract class LibraryPageState with _$LibraryPageState {
  const factory LibraryPageState({
    @Default(<Comic>[]) List<Comic> rawList,
    @Default(false) bool hasReceivedFirstEmit,
    Object? streamError,
    LibraryComicFilter? filter,
    LibraryComicSortOption? sortOption,
    @Default('') String mergeSearchQuery,
    @Default(true) bool isGridView,
  }) = _LibraryPageState;

  const LibraryPageState._();

  LibraryComicFilter get effectiveFilter =>
      filter ?? LibraryComicFilter(showR18: true);

  LibraryComicSortOption get effectiveSortOption =>
      sortOption ?? LibraryComicSortOption();
}

extension LibraryPageStateDerived on LibraryPageState {
  List<Comic> get displayedComics => applyLibraryDisplayedComicsQuery(this);

  AsyncValue<List<Comic>> get comicsAsyncValue =>
      buildLibraryComicsAsyncValue(this);

  AsyncValue<List<Comic>> get rawComicsAsyncValue {
    if (streamError != null) {
      return AsyncValue.error(streamError!, StackTrace.current);
    }
    if (!hasReceivedFirstEmit) {
      return const AsyncValue.loading();
    }
    return AsyncValue.data(rawList);
  }
}

@immutable
class LibrarySeriesViewData {
  const LibrarySeriesViewData({
    required this.headerTotalSeriesWithItemsCount,
    required this.seriesWithItemsCount,
    required this.filteredSeries,
  });

  /// 有子项的系列总数（含 R18），供漫画库页头 chip 显示全量。
  final int headerTotalSeriesWithItemsCount;

  /// 当前可见系列数（健全模式会排除含 R18 漫画的系列）；不含搜索关键字过滤。
  final int seriesWithItemsCount;
  final List<Series> filteredSeries;
}

@Riverpod(keepAlive: true)
class LibraryPageNotifier extends _$LibraryPageNotifier {
  static const _filterDebounceDuration = Duration(milliseconds: 300);
  static const _mergeSearchDebounceDuration = Duration(milliseconds: 500);
  Timer? _filterQueryDebounce;
  Timer? _mergeSearchDebounce;

  @override
  LibraryPageState build() {
    ref.listen<AsyncValue<AppSetting>>(settingsProvider, (prev, next) {
      next.whenData((settings) {
        final showR18 = !settings.isHealthyMode;
        if (state.effectiveFilter.showR18 == showR18) return;
        state = state.copyWith(
          filter: state.effectiveFilter.copyWith(showR18: showR18),
        );
      });
    });
    ref.listen<ComicAggregateState>(comicAggregateProvider, (
      ComicAggregateState? previous,
      ComicAggregateState next,
    ) {
      state = state.copyWith(
        rawList: next.rawList,
        hasReceivedFirstEmit: next.hasReceivedFirstEmit,
        streamError: next.streamError,
      );
    });

    ref.onDispose(() {
      _filterQueryDebounce?.cancel();
      _mergeSearchDebounce?.cancel();
    });

    final bool initialShowR18 =
        !((ref.read(settingsProvider).asData?.value.isHealthyMode) ?? false);
    final ComicAggregateState aggregateState = ref.read(comicAggregateProvider);
    return LibraryPageState(
      rawList: aggregateState.rawList,
      hasReceivedFirstEmit: aggregateState.hasReceivedFirstEmit,
      streamError: aggregateState.streamError,
      filter: LibraryComicFilter(showR18: initialShowR18),
    );
  }

  void refreshStream() {
    ref.read(comicAggregateProvider.notifier).refreshStream();
  }

  void _debounceFilter(void Function() action) {
    _filterQueryDebounce?.cancel();
    _filterQueryDebounce = Timer(_filterDebounceDuration, action);
  }

  void _debounceMergeSearch(void Function() action) {
    _mergeSearchDebounce?.cancel();
    _mergeSearchDebounce = Timer(_mergeSearchDebounceDuration, action);
  }

  // Filter APIs
  void updateFilterQuery(String? query) {
    _debounceFilter(() {
      state = state.copyWith(
        filter: state.effectiveFilter.copyWith(query: query),
      );
    });
  }

  void updateResourceTypes(Set<ResourceType> types) {
    state = state.copyWith(
      filter: state.effectiveFilter.copyWith(
        resourceTypes: types.isEmpty ? null : types,
      ),
    );
  }

  void updateContentRatings(Set<ContentRating> ratings) {
    state = state.copyWith(
      filter: state.effectiveFilter.copyWith(
        contentRatings: ratings.isEmpty ? null : ratings,
      ),
    );
  }

  void updateDisplayTarget(LibraryDisplayTarget target) {
    state = state.copyWith(
      filter: state.effectiveFilter.copyWith(displayTarget: target),
    );
  }

  void resetFilter() {
    state = state.copyWith(
      filter: LibraryComicFilter(showR18: state.effectiveFilter.showR18),
    );
  }

  // Sort APIs
  void toggleSortDescending(bool descending) {
    state = state.copyWith(
      sortOption: state.effectiveSortOption.copyWith(descending: descending),
    );
  }

  void updateSortField(LibraryComicSortField field) {
    state = state.copyWith(
      sortOption: state.effectiveSortOption.copyWith(field: field),
    );
  }

  void resetSortOption() {
    state = state.copyWith(sortOption: LibraryComicSortOption());
  }

  void updateMergeSearch(String value) {
    _debounceMergeSearch(() {
      state = state.copyWith(mergeSearchQuery: value);
    });
  }

  void setGridView(bool value) {
    state = state.copyWith(isGridView: value);
  }

  Comic? comicById(String id) {
    return state.rawList.firstWhereOrNull((c) => c.comicId == id);
  }
}

@riverpod
Future<List<Comic>> filteredMergeComics(
  Ref ref, {
  required String comicId,
}) async {
  final List<Comic> comics = ref.watch(
    libraryPageProvider.select((LibraryPageState s) => s.rawList),
  );
  final String query = ref.watch(
    libraryPageProvider.select((LibraryPageState s) => s.mergeSearchQuery),
  );
  final List<Comic> filtered = comics
      .where((Comic e) => e.comicId != comicId)
      .toList();
  if (query.isEmpty) return filtered;
  final String q = query.toLowerCase();
  return filtered
      .where((Comic e) => e.title.toLowerCase().contains(q))
      .toList();
}

@Riverpod(keepAlive: true)
Set<String> libraryComicIdsInAnySeries(Ref ref) {
  final AsyncValue<List<Series>> async = ref.watch(allSeriesProvider);
  return async.maybeWhen(
    data: (List<Series> list) {
      final Set<String> out = <String>{};
      for (final Series s in list) {
        for (final SeriesItem item in s.items) {
          out.add(item.comicId);
        }
      }
      return out;
    },
    orElse: () => <String>{},
  );
}

@Riverpod(keepAlive: true)
AsyncValue<List<Comic>> libraryDisplayedComics(Ref ref) {
  final _LibraryComicsStreamInput input = ref.watch(
    libraryPageProvider.select(
      (LibraryPageState s) => _LibraryComicsStreamInput(
        rawList: s.rawList,
        filter: s.effectiveFilter,
        sortOption: s.effectiveSortOption,
        hasReceivedFirstEmit: s.hasReceivedFirstEmit,
        streamError: s.streamError,
      ),
    ),
  );
  final bool hideComicsInSeries = ref.watch(
    settingsProvider.select(
      (AsyncValue<AppSetting> async) =>
          async.asData?.value.libraryHideComicsInSeries ?? false,
    ),
  );
  final Set<String> seriesComicIds = ref.watch(
    libraryComicIdsInAnySeriesProvider,
  );
  if (input.streamError != null) {
    return AsyncValue.error(input.streamError!, StackTrace.current);
  }
  if (!input.hasReceivedFirstEmit) {
    return const AsyncValue.loading();
  }
  final LibraryComicFilter filter = input.filter.copyWith(
    comicIdsExcludedBySeriesMembership: hideComicsInSeries
        ? seriesComicIds
        : null,
  );
  return AsyncValue.data(
    ComicQuery(
      filter: filter,
      sortOption: input.sortOption,
    ).apply(input.rawList),
  );
}

@Riverpod(keepAlive: true)
int libraryDisplayedComicCount(Ref ref) {
  final AsyncValue<List<Comic>> displayedAsync = ref.watch(
    libraryDisplayedComicsProvider,
  );
  return displayedAsync.maybeWhen(
    data: (List<Comic> comics) => comics.length,
    orElse: () => 0,
  );
}

final Provider<int> libraryDisplayedSeriesCountProvider = Provider<int>((
  Ref ref,
) {
  final LibrarySeriesViewData viewData = ref.watch(
    librarySeriesViewDataProvider,
  );
  return viewData.filteredSeries.length;
});

@Riverpod(keepAlive: true)
LibrarySeriesViewData librarySeriesViewData(Ref ref) {
  final AsyncValue<List<Series>> seriesAsync = ref.watch(allSeriesProvider);
  final bool showR18 = ref.watch(
    libraryPageProvider.select(
      (LibraryPageState s) => s.effectiveFilter.showR18,
    ),
  );
  final List<Comic> rawComics = ref.watch(
    libraryPageProvider.select((LibraryPageState s) => s.rawList),
  );
  final String query = ref.watch(
    libraryPageProvider.select(
      (LibraryPageState s) => s.effectiveFilter.query ?? '',
    ),
  );
  final LibraryComicSortOption sortOption = ref.watch(
    libraryPageProvider.select((LibraryPageState s) => s.effectiveSortOption),
  );
  return seriesAsync.when(
    data: (List<Series> list) {
      final Map<String, Comic> comicsById = <String, Comic>{};
      for (final Comic comic in rawComics) {
        comicsById[comic.comicId] = comic;
      }
      final String q = query.trim().toLowerCase();
      int headerTotalWithItems = 0;
      for (final Series s in list) {
        if (s.items.isNotEmpty) {
          headerTotalWithItems++;
        }
      }
      int count = 0;
      final List<Series> out = <Series>[];
      for (final Series s in list) {
        if (s.items.isEmpty) {
          continue;
        }
        if (!showR18 && s.hasR18Comic(comicsById: comicsById)) {
          continue;
        }
        count++;
        if (q.isEmpty || s.name.toLowerCase().contains(q)) {
          out.add(s);
        }
      }
      final List<Series> sortedOut = applyLibraryDisplayedSeriesSort(
        seriesList: out,
        sortOption: sortOption,
      );
      return LibrarySeriesViewData(
        headerTotalSeriesWithItemsCount: headerTotalWithItems,
        seriesWithItemsCount: count,
        filteredSeries: sortedOut,
      );
    },
    loading: () => const LibrarySeriesViewData(
      headerTotalSeriesWithItemsCount: 0,
      seriesWithItemsCount: 0,
      filteredSeries: <Series>[],
    ),
    error: (Object _, StackTrace _) => const LibrarySeriesViewData(
      headerTotalSeriesWithItemsCount: 0,
      seriesWithItemsCount: 0,
      filteredSeries: <Series>[],
    ),
    skipLoadingOnReload: true,
  );
}
