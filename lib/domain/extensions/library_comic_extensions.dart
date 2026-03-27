import 'package:hentai_library/domain/entity/comic/library_comic.dart';
import 'package:hentai_library/domain/value_objects/library_comic_filter.dart';
import 'package:hentai_library/domain/value_objects/library_comic_sort_option.dart';

extension LibraryComicSortX on List<LibraryComic> {
  List<LibraryComic> sortedWith(LibraryComicSortOption option) {
    return toList()..sort((a, b) => option.compare(a, b));
  }
}

extension LibraryComicFilterX on List<LibraryComic> {
  List<LibraryComic> applyFilter(LibraryComicFilter filter) {
    return where(filter.matches).toList();
  }
}
