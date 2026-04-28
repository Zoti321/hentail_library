import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/model/entity/comic/comic.dart';
import 'package:hentai_library/model/entity/comic/series.dart';
import 'package:hentai_library/model/entity/comic/series_item.dart';
import 'package:hentai_library/model/models.dart' show AppSetting;
import 'package:hentai_library/module/comic_list_query/comic_list_query.dart';
import 'package:hentai_library/presentation/providers/aggregates/comic_aggregate_notifier.dart';
import 'package:hentai_library/presentation/providers/aggregates/series_aggregate_notifier.dart';
import 'package:hentai_library/presentation/providers/deps/tools.dart';
import 'package:hentai_library/presentation/providers/pages/library/library_query_intent.dart';
import 'package:hentai_library/presentation/providers/pages/library/library_query_intent_notifier.dart';
import 'package:hentai_library/presentation/providers/pages/settings/settings_notifier.dart';

/// Projection 层（漫画）：把数据源、设置与 intent 合成为页面可直接消费的只读结果。
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
    if (identical(this, other)) {
      return true;
    }
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

final libraryComicByIdProvider = Provider.family<Comic?, String>((
  Ref ref,
  String comicId,
) {
  final List<Comic> comics = ref.watch(
    comicAggregateProvider.select((ComicAggregateState s) => s.rawList),
  );
  for (final Comic comic in comics) {
    if (comic.comicId == comicId) {
      return comic;
    }
  }
  return null;
});

/// 合并弹窗专用查询：基于当前关键字对“可合并漫画”做过滤。
final filteredMergeComicsProvider = FutureProvider.family<List<Comic>, String>((
  Ref ref,
  String comicId,
) async {
  final List<Comic> comics = ref.watch(
    comicAggregateProvider.select((ComicAggregateState s) => s.rawList),
  );
  final String query = ref.watch(
    libraryQueryIntentProvider.select(
      (LibraryQueryIntent s) => s.mergeSearchQuery,
    ),
  );
  final List<Comic> filtered = comics
      .where((Comic e) => e.comicId != comicId)
      .toList();
  if (query.isEmpty) {
    return filtered;
  }
  final String lowerQuery = query.toLowerCase();
  return filtered
      .where((Comic e) => e.title.toLowerCase().contains(lowerQuery))
      .toList();
});

final Provider<Set<String>> libraryComicIdsInAnySeriesProvider =
    Provider<Set<String>>((Ref ref) {
      final AsyncValue<List<Series>> seriesAsync = ref.watch(allSeriesProvider);
      return seriesAsync.maybeWhen(
        data: (List<Series> list) {
          final Set<String> out = <String>{};
          for (final Series series in list) {
            for (final SeriesItem item in series.items) {
              out.add(item.comicId);
            }
          }
          return out;
        },
        orElse: () => <String>{},
      );
    });

/// 漫画主列表投影：这里统一处理 loading/error/data 以及业务过滤和排序。
final Provider<AsyncValue<List<Comic>>> libraryDisplayedComicsProvider =
    Provider<AsyncValue<List<Comic>>>((Ref ref) {
      final ComicAggregateState aggregateState = ref.watch(
        comicAggregateProvider,
      );
      final LibraryQueryIntent intent = ref.watch(libraryQueryIntentProvider);
      final bool showR18 = !ref.watch(
        settingsProvider.select(
          (AsyncValue<AppSetting> async) =>
              async.asData?.value.isHealthyMode ?? false,
        ),
      );
      final _LibraryComicsStreamInput input = _LibraryComicsStreamInput(
        rawList: aggregateState.rawList,
        filter: intent.buildBaseFilter(showR18: showR18),
        sortOption: intent.sortOption,
        hasReceivedFirstEmit: aggregateState.hasReceivedFirstEmit,
        streamError: aggregateState.streamError,
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
        ref.read(comicListQueryModuleProvider).apply(
          comics: input.rawList,
          filter: filter,
          sortOption: input.sortOption,
        ),
      );
    });

/// 原始漫画流投影：供详情页、对话框等场景复用。
final Provider<AsyncValue<List<Comic>>>
libraryRawComicsAsyncProvider = Provider<AsyncValue<List<Comic>>>((Ref ref) {
  final ComicAggregateState aggregateState = ref.watch(comicAggregateProvider);
  if (aggregateState.streamError != null) {
    return AsyncValue.error(aggregateState.streamError!, StackTrace.current);
  }
  if (!aggregateState.hasReceivedFirstEmit) {
    return const AsyncValue.loading();
  }
  return AsyncValue.data(aggregateState.rawList);
});

final Provider<int> libraryDisplayedComicCountProvider = Provider<int>((
  Ref ref,
) {
  final AsyncValue<List<Comic>> displayedAsync = ref.watch(
    libraryDisplayedComicsProvider,
  );
  return displayedAsync.maybeWhen(
    data: (List<Comic> comics) => comics.length,
    orElse: () => 0,
  );
});

final Provider<bool> libraryHasReceivedFirstEmitProvider = Provider<bool>((
  Ref ref,
) {
  return ref.watch(
    comicAggregateProvider.select(
      (ComicAggregateState s) => s.hasReceivedFirstEmit,
    ),
  );
});

/// Action 门面：UI 只拿到一个刷新动作，不再依赖旧页面状态 notifier。
final Provider<VoidCallback> libraryRefreshActionProvider =
    Provider<VoidCallback>((Ref ref) {
      return () => ref.read(comicAggregateProvider.notifier).refreshStream();
    });
