import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/domain/models/entity/comic/comic.dart';
import 'package:hentai_library/ui/features/library/view_models/library_comics_catalog_controller.dart';
import 'package:hentai_library/ui/features/library/view_models/library_query_intent.dart';
import 'package:hentai_library/ui/features/library/view_models/library_query_intent_notifier.dart';
import 'package:hentai_library/ui/features/library/view_models/library_series_catalog_controller.dart';
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
      (LibraryQueryIntent state) => state.mergeSearchQuery,
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
        ref.read(libraryComicsCatalogControllerProvider.notifier).refresh();
        ref.read(librarySeriesCatalogControllerProvider.notifier).refresh();
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
