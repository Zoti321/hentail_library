import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/domain/entity/comic/comic.dart';
import 'package:hentai_library/domain/value_objects/library_display_target.dart';
import 'package:hentai_library/presentation/providers/pages/library/library_page_comics_providers.dart';
import 'package:hentai_library/presentation/providers/pages/library/library_page_series_providers.dart';
import 'package:hentai_library/presentation/providers/pages/library/library_query_intent.dart';
import 'package:hentai_library/presentation/providers/pages/library/library_query_intent_notifier.dart';

/// Facade/ViewModel 层：把多个投影 provider 收敛成页面渲染的单一读取入口。
class LibraryPageViewModel {
  const LibraryPageViewModel({
    required this.comicsAsync,
    required this.seriesViewData,
    required this.displayedComicCount,
    required this.displayedSeriesCount,
    required this.isGridView,
    required this.displayTarget,
    required this.filterQuery,
    required this.hasReceivedFirstEmit,
    required this.isComicTableEmpty,
  });
  final AsyncValue<List<Comic>> comicsAsync;
  final LibrarySeriesViewData seriesViewData;
  final int displayedComicCount;
  final int displayedSeriesCount;
  final bool isGridView;
  final LibraryDisplayTarget displayTarget;
  final String filterQuery;
  final bool hasReceivedFirstEmit;
  final bool isComicTableEmpty;
}

/// 细粒度 UI 选择器：给工具条/布局切换等局部组件直接订阅。
final libraryDisplayTargetProvider = Provider<LibraryDisplayTarget>((Ref ref) {
  return ref.watch(
    libraryQueryIntentProvider.select(
      (LibraryQueryIntent s) => s.displayTarget,
    ),
  );
});

final libraryFilterQueryProvider = Provider<String>((Ref ref) {
  return ref.watch(
    libraryQueryIntentProvider.select((LibraryQueryIntent s) => s.keyword),
  );
});

final libraryIsGridViewProvider = Provider<bool>((Ref ref) {
  return ref.watch(
    libraryQueryIntentProvider.select(
      (LibraryQueryIntent s) => s.isGridView,
    ),
  );
});

/// 页面级只读模型：UI 层优先消费这个 provider，减少组件内拼装逻辑。
final libraryPageViewModelProvider = Provider<LibraryPageViewModel>((Ref ref) {
  final AsyncValue<List<Comic>> comicsAsync = ref.watch(
    libraryDisplayedComicsProvider,
  );
  final LibrarySeriesViewData seriesViewData = ref.watch(
    librarySeriesViewDataProvider,
  );
  final int displayedComicCount = ref.watch(libraryDisplayedComicCountProvider);
  final int displayedSeriesCount = ref.watch(libraryDisplayedSeriesCountProvider);
  final bool isGridView = ref.watch(libraryIsGridViewProvider);
  final LibraryDisplayTarget displayTarget = ref.watch(libraryDisplayTargetProvider);
  final String filterQuery = ref.watch(libraryFilterQueryProvider);
  final bool hasReceivedFirstEmit = ref.watch(libraryHasReceivedFirstEmitProvider);
  final bool isComicTableEmpty = hasReceivedFirstEmit && displayedComicCount == 0;
  return LibraryPageViewModel(
    comicsAsync: comicsAsync,
    seriesViewData: seriesViewData,
    displayedComicCount: displayedComicCount,
    displayedSeriesCount: displayedSeriesCount,
    isGridView: isGridView,
    displayTarget: displayTarget,
    filterQuery: filterQuery,
    hasReceivedFirstEmit: hasReceivedFirstEmit,
    isComicTableEmpty: isComicTableEmpty,
  );
});
