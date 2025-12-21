import 'package:hentai_library/domain/entity/entities.dart';
import 'package:hentai_library/domain/value_objects/comic_filter.dart';
import 'package:hentai_library/domain/value_objects/comic_sort_option.dart';

// 漫画排序
extension ComicSortX on List<Comic> {
  List<Comic> sortedWith(ComicSortOption option) {
    // 使用 toList() 保证不修改原始列表，符合函数式编程思想
    return toList()..sort((a, b) => option.compare(a, b));
  }
}

// 漫画过滤：委托给 ComicFilter.matches，扩展仅负责应用到列表
extension ComicFilterX on List<Comic> {
  List<Comic> applyFilter(ComicFilter filter) {
    return where((comic) => filter.matches(comic)).toList();
  }
}
