import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/domain/models/entity/comic/series.dart';
import 'package:hentai_library/domain/models/value_objects/paged_result.dart';
import 'package:hentai_library/ui/features/library/view_models/library_page_comics_providers.dart';
import 'package:hentai_library/ui/features/library/view_models/library_page_pagination_providers.dart';

/// 搜索页等场景复用的系列列表视图 DTO（数据来自 Rust search / 分页 API）。
@immutable
class LibrarySeriesViewData {
  const LibrarySeriesViewData({
    required this.headerTotalSeriesWithItemsCount,
    required this.seriesWithItemsCount,
    required this.filteredSeries,
  });
  final int headerTotalSeriesWithItemsCount;
  final int seriesWithItemsCount;
  final List<Series> filteredSeries;
}

/// 当前页系列条目（供库页网格消费；筛选/分页由 Rust [librarySeriesPageProvider] 负责）。
final Provider<AsyncValue<List<Series>>> libraryDisplayedSeriesProvider =
    Provider<AsyncValue<List<Series>>>((Ref ref) {
      final AsyncValue<PagedResult<Series>> pageAsync = ref.watch(
        librarySeriesPageProvider,
      );
      return pageAsync.when(
        data: (PagedResult<Series> page) => AsyncValue.data(page.items),
        loading: () => const AsyncValue.loading(),
        error: (Object error, StackTrace stackTrace) =>
            AsyncValue.error(error, stackTrace),
        skipLoadingOnReload: true,
      );
    });

final Provider<int> libraryDisplayedSeriesCountProvider = Provider<int>((
  Ref ref,
) {
  final AsyncValue<PagedResult<Series>> pageAsync = ref.watch(
    librarySeriesPageProvider,
  );
  return stablePagedTotalCount(pageAsync);
});
