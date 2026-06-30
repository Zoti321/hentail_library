import 'package:hentai_library/domain/models/enums.dart';
import 'package:hentai_library/domain/library/comic_list_query.dart';

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
