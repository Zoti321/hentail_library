import 'package:hentai_library/domain/value_objects/library_comic_filter.dart';
import 'package:hentai_library/domain/value_objects/library_comic_sort_option.dart';
import 'package:hentai_library/domain/value_objects/library_display_target.dart';

/// Intent 层：只表达“用户想看什么”，不处理数据源订阅与派生计算。
class LibraryQueryIntent {
  LibraryQueryIntent({
    this.keyword = '',
    LibraryComicSortOption? sortOption,
    this.displayTarget = LibraryDisplayTarget.all,
    this.isGridView = true,
    this.mergeSearchQuery = '',
  }) : sortOption = sortOption ?? LibraryComicSortOption();
  final String keyword;
  final LibraryComicSortOption sortOption;
  final LibraryDisplayTarget displayTarget;
  final bool isGridView;
  final String mergeSearchQuery;

  /// 由 intent 组装基础过滤条件，数据层附加动态策略（如隐藏系列成员）后再执行查询。
  LibraryComicFilter buildBaseFilter({required bool showR18}) {
    return LibraryComicFilter(
      showR18: showR18,
      query: null,
      displayTarget: displayTarget,
    );
  }

  LibraryQueryIntent copyWith({
    String? keyword,
    LibraryComicSortOption? sortOption,
    LibraryDisplayTarget? displayTarget,
    bool? isGridView,
    String? mergeSearchQuery,
  }) {
    return LibraryQueryIntent(
      keyword: keyword ?? this.keyword,
      sortOption: sortOption ?? this.sortOption,
      displayTarget: displayTarget ?? this.displayTarget,
      isGridView: isGridView ?? this.isGridView,
      mergeSearchQuery: mergeSearchQuery ?? this.mergeSearchQuery,
    );
  }
}
