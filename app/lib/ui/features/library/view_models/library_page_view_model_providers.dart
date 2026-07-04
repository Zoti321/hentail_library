import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/domain/models/entity/comic/comic.dart';
import 'package:hentai_library/domain/models/entity/comic/series.dart';
import 'package:hentai_library/domain/models/enums.dart';
import 'package:hentai_library/domain/models/value_objects/paged_result.dart';
import 'package:hentai_library/ui/features/library/view_models/library_page_comics_providers.dart';
import 'package:hentai_library/ui/features/library/view_models/library_page_pagination_providers.dart';
import 'package:hentai_library/ui/features/library/view_models/library_page_series_providers.dart';
import 'package:hentai_library/ui/features/library/view_models/library_query_intent.dart';
import 'package:hentai_library/ui/features/library/view_models/library_query_intent_notifier.dart';

/// Facade/ViewModel 层：把多个投影 provider 收敛成页面渲染的单一读取入口。
class LibraryPageViewModel {
  const LibraryPageViewModel({
    required this.comicsAsync,
    required this.comicsPagination,
    required this.seriesAsync,
    required this.displayedComicCount,
    required this.displayedSeriesCount,
    required this.displayTarget,
    required this.filterQuery,
    required this.hasReceivedFirstEmit,
    required this.isComicTableEmpty,
    this.showPagination = true,
  });
  final AsyncValue<List<Comic>> comicsAsync;
  final LibraryComicsPagination comicsPagination;
  final AsyncValue<List<Series>> seriesAsync;
  final int displayedComicCount;
  final int displayedSeriesCount;
  final LibraryDisplayTarget displayTarget;
  final String filterQuery;
  final bool hasReceivedFirstEmit;
  final bool isComicTableEmpty;
  final bool showPagination;
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

/// 页面级只读模型：UI 层优先消费这个 provider，减少组件内拼装逻辑。
final libraryPageViewModelProvider = Provider<LibraryPageViewModel>((Ref ref) {
  final AsyncValue<List<Comic>> comicsAsync = ref.watch(
    libraryDisplayedComicsProvider,
  );
  final AsyncValue<PagedResult<Comic>> comicsPageAsync = ref.watch(
    libraryComicsPageProvider,
  );
  final AsyncValue<List<Series>> seriesAsync = ref.watch(
    libraryDisplayedSeriesProvider,
  );
  final int displayedComicCount = ref.watch(libraryDisplayedComicCountProvider);
  final int displayedSeriesCount = ref.watch(
    libraryDisplayedSeriesCountProvider,
  );
  final LibraryDisplayTarget displayTarget = ref.watch(
    libraryDisplayTargetProvider,
  );
  final String filterQuery = ref.watch(libraryFilterQueryProvider);
  final bool hasReceivedFirstEmit = ref.watch(
    libraryHasReceivedFirstEmitProvider,
  );
  final AsyncValue<int> tableTotalAsync = ref.watch(
    libraryComicTableTotalCountProvider,
  );
  final bool isComicTableEmpty = tableTotalAsync.maybeWhen(
    data: (int count) => hasReceivedFirstEmit && count == 0,
    orElse: () => false,
  );
  final LibraryComicsPagination pagination = comicsPageAsync.maybeWhen(
    data: (PagedResult<Comic> page) => LibraryComicsPagination(
      page: page.page,
      totalPages: page.totalPages,
      totalCount: page.totalCount,
      isLoading: false,
    ),
    orElse: () => const LibraryComicsPagination(
      page: 1,
      totalPages: 0,
      totalCount: 0,
      isLoading: true,
    ),
  );
  return LibraryPageViewModel(
    comicsAsync: comicsAsync,
    comicsPagination: pagination,
    seriesAsync: seriesAsync,
    displayedComicCount: displayedComicCount,
    displayedSeriesCount: displayedSeriesCount,
    displayTarget: displayTarget,
    filterQuery: filterQuery,
    hasReceivedFirstEmit: hasReceivedFirstEmit,
    isComicTableEmpty: isComicTableEmpty,
  );
});
