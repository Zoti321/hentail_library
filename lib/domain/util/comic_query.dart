import 'package:hentai_library/domain/entity/comic/comic.dart';
import 'package:hentai_library/domain/value_objects/library_comic_filter.dart';
import 'package:hentai_library/domain/value_objects/library_comic_sort_option.dart';

/// 漫画库列表的筛选 + 排序（内存侧单一入口，避免 UI/扩展方法间重复组合条件）。
///
/// 数据库侧若需相同语义，应在 DAO 层显式映射字段，而非复制 [LibraryComicFilter.matches] 逻辑。
class ComicQuery {
  const ComicQuery({required this.filter, required this.sortOption});

  final LibraryComicFilter filter;
  final LibraryComicSortOption sortOption;

  List<Comic> apply(Iterable<Comic> comics) {
    final list = comics.where(filter.matches).toList();
    list.sort((a, b) => sortOption.compare(a, b));
    return list;
  }
}
