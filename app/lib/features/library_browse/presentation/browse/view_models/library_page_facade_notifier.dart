import 'package:hentai_library/features/comic/domain/library_comic_grouping.dart';
import 'package:hentai_library/features/comic/domain/library_comic_sort_option.dart';
import 'package:hentai_library/features/library_browse/domain/browse/library_age_restriction_filter.dart';
import 'package:hentai_library/features/library_browse/domain/browse/library_tri_state_pick.dart';
import 'package:hentai_library/features/library_browse/presentation/browse/view_models/library_catalog_selectors.dart';
import 'package:hentai_library/features/library_browse/presentation/browse/view_models/library_catalog_state.dart';
import 'package:hentai_library/features/library_browse/presentation/browse/view_models/library_comic_filters_notifier.dart';
import 'package:hentai_library/features/library_browse/presentation/browse/view_models/library_comics_catalog_controller.dart';
import 'package:hentai_library/features/library_browse/presentation/browse/view_models/library_query_intent.dart';
import 'package:hentai_library/features/library_browse/presentation/browse/view_models/library_query_intent_notifier.dart';
import 'package:hentai_library/features/library_browse/presentation/browse/view_models/library_series_catalog_controller.dart';
import 'package:hentai_library/features/library_browse/presentation/browse/view_models/library_series_filters_notifier.dart';
import 'package:hentai_library/features/library_browse/presentation/browse/view_models/library_tab_filter_sort_providers.dart';
import 'package:hentai_library/features/library_browse/presentation/browse/view_models/library_tab_page_size_notifier.dart';
import 'package:hentai_library/features/library_browse/presentation/browse/view_models/library_tab_page_size_providers.dart';
import 'package:hentai_library/features/series/domain/library_serialization_status_filter.dart';
import 'package:hentai_library/features/series/domain/library_series_grouping.dart';
import 'package:hentai_library/features/series/domain/library_series_sort_option.dart';
import 'package:hentai_library/shared/domain/library/library_media_type_filter.dart';
import 'package:hentai_library/shared/domain/models/enums.dart';
import 'package:hentai_library/shared/domain/models/value_objects/page_jump.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'library_page_facade_notifier.g.dart';

/// 页码为 null 表示对应 Tab 的目录尚未加载出首帧。
///
/// [comicFilters] / [seriesFilters] 与 catalog 投影供叶子细粒度 `select`；
/// View 不得再直订 filters / catalog Controller。
typedef LibraryPageFacadeState = ({
  LibraryDisplayTarget displayTarget,
  String keyword,
  bool isFilterSortCustomized,
  int? comicsPage,
  int? seriesPage,
  int comicsPageSize,
  int seriesPageSize,
  int activePageSize,
  int displayedComicCount,
  int displayedSeriesCount,
  LibraryComicFiltersState comicFilters,
  LibrarySeriesFiltersState seriesFilters,
  AsyncValue<LibraryComicsCatalogState> comicsCatalog,
  AsyncValue<LibrarySeriesCatalogState> seriesCatalog,
});

/// 列表内容整体换页（切 Tab、翻页、改每页数量）时回到顶部；
/// 目录首帧加载或重载间隙（页码为 null）不算换页。
bool libraryPageShouldScrollToTop(
  LibraryPageFacadeState? previous,
  LibraryPageFacadeState next,
) {
  if (previous == null) {
    return false;
  }
  bool pageTurned(int? before, int? after) =>
      before != null && after != null && before != after;
  return previous.displayTarget != next.displayTarget ||
      pageTurned(previous.comicsPage, next.comicsPage) ||
      pageTurned(previous.seriesPage, next.seriesPage) ||
      previous.comicsPageSize != next.comicsPageSize ||
      previous.seriesPageSize != next.seriesPageSize;
}

/// 库页 Facade：View 的统一订阅与命令入口。
///
/// 只做命令转发与聚合 watch；查询意图、筛选、分页加载仍由各子 Notifier 负责。
@riverpod
class LibraryPageFacadeNotifier extends _$LibraryPageFacadeNotifier {
  @override
  LibraryPageFacadeState build() {
    final LibraryQueryIntent intent = ref.watch(libraryQueryIntentProvider);
    final AsyncValue<LibraryComicsCatalogState> comicsCatalog = ref.watch(
      libraryComicsCatalogControllerProvider,
    );
    final AsyncValue<LibrarySeriesCatalogState> seriesCatalog = ref.watch(
      librarySeriesCatalogControllerProvider,
    );
    final int comicsPageSize = ref.watch(libraryComicsTabPageSizeProvider);
    final int seriesPageSize = ref.watch(librarySeriesTabPageSizeProvider);
    return (
      displayTarget: intent.displayTarget,
      keyword: intent.keyword,
      isFilterSortCustomized: ref.watch(
        libraryActiveFilterSortIsCustomizedProvider,
      ),
      comicsPage: comicsCatalog.value?.pagination.page,
      seriesPage: seriesCatalog.value?.pagination.page,
      comicsPageSize: comicsPageSize,
      seriesPageSize: seriesPageSize,
      activePageSize: switch (intent.displayTarget) {
        LibraryDisplayTarget.comics => comicsPageSize,
        LibraryDisplayTarget.series => seriesPageSize,
      },
      displayedComicCount: stableCatalogDisplayedCount(
        comicsCatalog,
        readCount: (LibraryComicsCatalogState state) => state.displayedCount,
      ),
      displayedSeriesCount: stableCatalogDisplayedCount(
        seriesCatalog,
        readCount: (LibrarySeriesCatalogState state) => state.displayedCount,
      ),
      comicFilters:
          ref.watch(libraryComicFiltersProvider).value ??
          LibraryComicFiltersState.defaults,
      seriesFilters:
          ref.watch(librarySeriesFiltersProvider).value ??
          LibrarySeriesFiltersState.defaults,
      comicsCatalog: comicsCatalog,
      seriesCatalog: seriesCatalog,
    );
  }

  void selectDisplayTarget(LibraryDisplayTarget target) {
    ref.read(libraryQueryIntentProvider.notifier).setDisplayTarget(target);
  }

  /// 防抖后生效；连续调用只保留最后一次。
  void setKeyword(String? keyword) {
    ref.read(libraryQueryIntentProvider.notifier).setFilterQuery(keyword);
  }

  /// 重置当前 Tab 的筛选与排序；[clearKeyword] 为 true 时同时清空关键词。
  Future<void> resetFilters({bool clearKeyword = false}) async {
    final LibraryQueryIntentNotifier intent = ref.read(
      libraryQueryIntentProvider.notifier,
    );
    if (clearKeyword) {
      intent.clearKeyword();
    }
    switch (state.displayTarget) {
      case LibraryDisplayTarget.comics:
        await ref.read(libraryComicFiltersProvider.notifier).resetAll();
      case LibraryDisplayTarget.series:
        await ref.read(librarySeriesFiltersProvider.notifier).resetAll();
    }
  }

  /// 作用于当前 Tab；不在可选项内的值回落为默认值。
  Future<void> setPageSize(int pageSize) {
    return ref
        .read(libraryTabPageSizeProvider.notifier)
        .setPageSize(state.displayTarget, pageSize);
  }

  /// 直接跳到指定页（1-based）；越界或未变化时为 no-op。
  void setPage(LibraryDisplayTarget target, int page) {
    switch (target) {
      case LibraryDisplayTarget.comics:
        ref.read(libraryComicsCatalogControllerProvider.notifier).setPage(page);
      case LibraryDisplayTarget.series:
        ref.read(librarySeriesCatalogControllerProvider.notifier).setPage(page);
    }
  }

  /// 越界跳转（如末页再下一页）为 no-op；目录未加载时忽略。
  void jumpPage(LibraryDisplayTarget target, PageJump jump) {
    switch (target) {
      case LibraryDisplayTarget.comics:
        ref.read(libraryComicsCatalogControllerProvider.notifier).jump(jump);
      case LibraryDisplayTarget.series:
        ref.read(librarySeriesCatalogControllerProvider.notifier).jump(jump);
    }
  }

  Future<void> toggleAgeRestrictionOption(LibraryAgeRestrictionFilter option) {
    switch (state.displayTarget) {
      case LibraryDisplayTarget.comics:
        return ref
            .read(libraryComicFiltersProvider.notifier)
            .toggleAgeRestrictionOption(option);
      case LibraryDisplayTarget.series:
        return ref
            .read(librarySeriesFiltersProvider.notifier)
            .toggleAgeRestrictionOption(option);
    }
  }

  Future<void> toggleMediaType(LibraryMediaTypeFilterOption option) {
    return ref
        .read(libraryComicFiltersProvider.notifier)
        .toggleMediaType(option);
  }

  Future<void> toggleSerializationStatusFilterOption(
    LibrarySerializationStatusFilter option,
  ) {
    return ref
        .read(librarySeriesFiltersProvider.notifier)
        .toggleSerializationStatusFilterOption(option);
  }

  Future<void> setNeedsMetadataOnly(bool enabled) {
    return ref
        .read(libraryComicFiltersProvider.notifier)
        .setNeedsMetadataOnly(enabled);
  }

  Future<void> setComicGrouping(LibraryComicGrouping grouping) {
    return ref.read(libraryComicFiltersProvider.notifier).setGrouping(grouping);
  }

  Future<void> setSeriesGrouping(LibrarySeriesGrouping grouping) {
    return ref
        .read(librarySeriesFiltersProvider.notifier)
        .setGrouping(grouping);
  }

  Future<void> setComicSortField(LibraryComicSortField field) {
    return ref.read(libraryComicFiltersProvider.notifier).setSortField(field);
  }

  Future<void> setSeriesSortField(LibrarySeriesSortField field) {
    return ref.read(librarySeriesFiltersProvider.notifier).setSortField(field);
  }

  Future<void> toggleTag(String name) {
    return ref.read(libraryComicFiltersProvider.notifier).toggleTag(name);
  }

  Future<void> setTagIncludeMode(LibraryMetadataIncludeMode mode) {
    return ref
        .read(libraryComicFiltersProvider.notifier)
        .setTagIncludeMode(mode);
  }

  Future<void> clearTag() {
    return ref.read(libraryComicFiltersProvider.notifier).clearTag();
  }

  Future<void> toggleAuthor(String name) {
    return ref.read(libraryComicFiltersProvider.notifier).toggleAuthor(name);
  }

  Future<void> setAuthorIncludeMode(LibraryMetadataIncludeMode mode) {
    return ref
        .read(libraryComicFiltersProvider.notifier)
        .setAuthorIncludeMode(mode);
  }

  Future<void> clearAuthor() {
    return ref.read(libraryComicFiltersProvider.notifier).clearAuthor();
  }

  Future<void> toggleIncludeSet(LibraryIncludeSetKind kind, String name) {
    return ref
        .read(libraryComicFiltersProvider.notifier)
        .toggleIncludeSet(kind, name);
  }

  Future<void> clearIncludeSet(LibraryIncludeSetKind kind) {
    return ref.read(libraryComicFiltersProvider.notifier).clearIncludeSet(kind);
  }
}
