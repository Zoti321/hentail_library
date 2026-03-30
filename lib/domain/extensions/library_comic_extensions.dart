import 'package:hentai_library/domain/entity/comic/comic.dart';
import 'package:hentai_library/domain/value_objects/library_comic_filter.dart';
import 'package:hentai_library/domain/value_objects/library_comic_sort_option.dart';

extension LibraryComicSortX on List<Comic> {
  List<Comic> sortedWith(LibraryComicSortOption option) {
    return toList()..sort((a, b) => option.compare(a, b));
  }
}

extension LibraryComicFilterX on List<Comic> {
  List<Comic> applyFilter(LibraryComicFilter filter) {
    return where(filter.matches).toList();
  }
}
