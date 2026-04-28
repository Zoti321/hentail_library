import 'package:hentai_library/model/entity/comic/comic.dart';
import 'package:hentai_library/module/comic_list_query/comic_query.dart';
import 'package:hentai_library/module/comic_list_query/library_comic_filter.dart';
import 'package:hentai_library/module/comic_list_query/library_comic_sort_option.dart';

extension ComicSortX on List<Comic> {
  List<Comic> sortedWith(LibraryComicSortOption option) {
    return toList()..sort((a, b) => option.compare(a, b));
  }
}

extension ComicFilterX on List<Comic> {
  /// 仅筛选；需要与 [LibraryComicSortOption] 组合时请用 [ComicQuery.apply]。
  List<Comic> applyFilter(LibraryComicFilter filter) {
    return where(filter.matches).toList();
  }
}
