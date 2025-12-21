import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/domain/models/entity/comic/comic.dart';
import 'package:hentai_library/domain/models/value_objects/paged_result.dart';
import 'package:hentai_library/ui/features/library/view_models/library_page_pagination_providers.dart';
import 'package:hentai_library/ui/features/library/view_models/library_query_intent.dart';
import 'package:hentai_library/ui/features/library/view_models/library_query_intent_notifier.dart';
import 'package:hentai_library/ui/features/shell/di/deps.dart';
import 'package:hentai_library/ui/features/shell/state/comic_aggregate_notifier.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'library_page_comics_providers.g.dart';

@Riverpod(keepAlive: true)
Future<Comic?> libraryComicById(Ref ref, String comicId) {
  ref.watch(
    comicAggregateProvider.select(
      (ComicAggregateState s) => s.changeGeneration,
    ),
  );
  return ref.read(comicRepoProvider).findById(comicId);
}

/// 合并弹窗专用查询：基于当前关键字对“可合并漫画”做过滤。
@Riverpod(keepAlive: true)
Future<List<Comic>> filteredMergeComics(Ref ref, String comicId) async {
  ref.watch(
    comicAggregateProvider.select(
      (ComicAggregateState s) => s.changeGeneration,
    ),
  );
  final String query = ref.watch(
    libraryQueryIntentProvider.select(
      (LibraryQueryIntent s) => s.mergeSearchQuery,
    ),
  );
  final List<Comic> comics = await ref.read(comicRepoProvider).getAll();
  final List<Comic> filtered = comics
      .where((Comic comic) => comic.comicId != comicId)
      .toList();
  if (query.isEmpty) {
    return filtered;
  }
  final String lowerQuery = query.toLowerCase();
  return filtered
      .where((Comic comic) => comic.title.toLowerCase().contains(lowerQuery))
      .toList();
}

/// 漫画主列表：分页读取当前页。
final Provider<AsyncValue<PagedResult<Comic>>> libraryComicsPageAsyncProvider =
    Provider<AsyncValue<PagedResult<Comic>>>((Ref ref) {
      return ref.watch(libraryComicsPageProvider);
    });

/// 当前页漫画条目（供现有 UI 组件消费）。
final Provider<AsyncValue<List<Comic>>> libraryDisplayedComicsProvider =
    Provider<AsyncValue<List<Comic>>>((Ref ref) {
      final AsyncValue<PagedResult<Comic>> pageAsync = ref.watch(
        libraryComicsPageProvider,
      );
      return pageAsync.when(
        data: (PagedResult<Comic> page) => AsyncValue.data(page.items),
        loading: () => const AsyncValue.loading(),
        error: (Object error, StackTrace stackTrace) =>
            AsyncValue.error(error, stackTrace),
        skipLoadingOnReload: true,
      );
    });

final Provider<int> libraryDisplayedComicCountProvider = Provider<int>((
  Ref ref,
) {
  final AsyncValue<PagedResult<Comic>> pageAsync = ref.watch(
    libraryComicsPageProvider,
  );
  return pageAsync.maybeWhen(
    data: (PagedResult<Comic> page) => page.totalCount,
    orElse: () => 0,
  );
});

final Provider<bool> libraryHasReceivedFirstEmitProvider = Provider<bool>((
  Ref ref,
) {
  return ref.watch(
    comicAggregateProvider.select(
      (ComicAggregateState s) => s.hasReceivedFirstChange,
    ),
  );
});

/// Action 门面：刷新变更通知并重置到第一页。
final Provider<VoidCallback> libraryRefreshActionProvider =
    Provider<VoidCallback>((Ref ref) {
      return () {
        ref.read(comicAggregateProvider.notifier).refreshStream();
        ref.read(libraryComicsPageIndexProvider.notifier).resetToFirstPage();
        ref.invalidate(libraryComicsPageProvider);
      };
    });

@Riverpod(keepAlive: true)
Future<Comic?> libraryComicDetail(Ref ref, String comicId) {
  ref.watch(
    comicAggregateProvider.select(
      (ComicAggregateState s) => s.changeGeneration,
    ),
  );
  return ref.read(comicRepoProvider).findById(comicId);
}
