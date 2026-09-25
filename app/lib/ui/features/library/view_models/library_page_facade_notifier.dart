import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/domain/models/enums.dart';
import 'package:hentai_library/ui/features/library/view_models/library_catalog_selectors.dart';
import 'package:hentai_library/ui/features/library/view_models/library_catalog_state.dart';
import 'package:hentai_library/ui/features/library/view_models/library_comics_catalog_controller.dart';
import 'package:hentai_library/ui/features/library/view_models/library_comics_filter_reset_notifier.dart';
import 'package:hentai_library/ui/features/library/view_models/library_query_intent.dart';
import 'package:hentai_library/ui/features/library/view_models/library_query_intent_notifier.dart';
import 'package:hentai_library/ui/features/library/view_models/library_series_catalog_controller.dart';
import 'package:hentai_library/ui/features/library/view_models/library_series_filter_reset_notifier.dart';
import 'package:hentai_library/ui/features/library/view_models/library_tab_filter_sort_providers.dart';
import 'package:hentai_library/ui/features/library/view_models/library_tab_page_size_notifier.dart';
import 'package:hentai_library/ui/features/library/view_models/library_tab_page_size_providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'library_page_facade_notifier.g.dart';

enum LibraryPageJump { first, previous, next, last }

/// 页码为 null 表示对应 Tab 的目录尚未加载出首帧。
typedef LibraryPageFacadeState = ({
  LibraryDisplayTarget displayTarget,
  String keyword,
  bool isFilterSortCustomized,
  int? comicsPage,
  int? seriesPage,
  int comicsPageSize,
  int seriesPageSize,
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
/// 目录相关字段读自可被 override 的 `*CatalogContentProvider`。
@riverpod
class LibraryPageFacadeNotifier extends _$LibraryPageFacadeNotifier {
  @override
  LibraryPageFacadeState build() {
    final LibraryQueryIntent intent = ref.watch(libraryQueryIntentProvider);
    return (
      displayTarget: intent.displayTarget,
      keyword: intent.keyword,
      isFilterSortCustomized: ref.watch(
        libraryActiveFilterSortIsCustomizedProvider,
      ),
      comicsPage: ref.watch(
        libraryComicsCatalogContentProvider.select(
          (AsyncValue<LibraryComicsCatalogState> async) =>
              async.value?.pagination.page,
        ),
      ),
      seriesPage: ref.watch(
        librarySeriesCatalogContentProvider.select(
          (AsyncValue<LibrarySeriesCatalogState> async) =>
              async.value?.pagination.page,
        ),
      ),
      comicsPageSize: ref.watch(libraryComicsTabPageSizeProvider),
      seriesPageSize: ref.watch(librarySeriesTabPageSizeProvider),
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
        await ref.read(libraryComicsFilterResetProvider.notifier).resetAll();
      case LibraryDisplayTarget.series:
        await ref.read(librarySeriesFilterResetProvider.notifier).resetAll();
    }
  }

  /// 作用于当前 Tab；不在可选项内的值回落为默认值。
  Future<void> setPageSize(int pageSize) {
    return ref
        .read(libraryTabPageSizeProvider.notifier)
        .setPageSize(state.displayTarget, pageSize);
  }

  /// 越界跳转（如末页再下一页）为 no-op；目录未加载时忽略。
  void jumpPage(LibraryDisplayTarget target, LibraryPageJump jump) {
    switch (target) {
      case LibraryDisplayTarget.comics:
        final int? totalPages = ref
            .read(libraryComicsCatalogContentProvider)
            .value
            ?.pagination
            .totalPages;
        if (totalPages == null) {
          return;
        }
        final LibraryComicsCatalogController catalog = ref.read(
          libraryComicsCatalogControllerProvider.notifier,
        );
        switch (jump) {
          case LibraryPageJump.first:
            catalog.goToFirstPage();
          case LibraryPageJump.previous:
            catalog.goToPreviousPage();
          case LibraryPageJump.next:
            catalog.goToNextPage(totalPages);
          case LibraryPageJump.last:
            catalog.goToLastPage(totalPages);
        }
      case LibraryDisplayTarget.series:
        final int? totalPages = ref
            .read(librarySeriesCatalogContentProvider)
            .value
            ?.pagination
            .totalPages;
        if (totalPages == null) {
          return;
        }
        final LibrarySeriesCatalogController catalog = ref.read(
          librarySeriesCatalogControllerProvider.notifier,
        );
        switch (jump) {
          case LibraryPageJump.first:
            catalog.goToFirstPage();
          case LibraryPageJump.previous:
            catalog.goToPreviousPage();
          case LibraryPageJump.next:
            catalog.goToNextPage(totalPages);
          case LibraryPageJump.last:
            catalog.goToLastPage(totalPages);
        }
    }
  }
}
