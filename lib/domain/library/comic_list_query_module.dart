import 'package:hentai_library/model/entity/comic/comic.dart';
import 'package:hentai_library/module/comic_list_query/comic_query.dart';
import 'package:hentai_library/module/comic_list_query/library_comic_filter.dart';
import 'package:hentai_library/module/comic_list_query/library_comic_sort_option.dart';

abstract interface class ComicListQueryModule {
  List<Comic> apply({
    required Iterable<Comic> comics,
    required LibraryComicFilter filter,
    required LibraryComicSortOption sortOption,
  });

  List<Comic> filter({
    required Iterable<Comic> comics,
    required LibraryComicFilter filter,
  });

  List<Comic> sort({
    required List<Comic> comics,
    required LibraryComicSortOption sortOption,
  });
}

class DefaultComicListQueryModule implements ComicListQueryModule {
  const DefaultComicListQueryModule();

  @override
  List<Comic> apply({
    required Iterable<Comic> comics,
    required LibraryComicFilter filter,
    required LibraryComicSortOption sortOption,
  }) {
    return ComicQuery(filter: filter, sortOption: sortOption).apply(comics);
  }

  @override
  List<Comic> filter({
    required Iterable<Comic> comics,
    required LibraryComicFilter filter,
  }) {
    return comics.where(filter.matches).toList();
  }

  @override
  List<Comic> sort({
    required List<Comic> comics,
    required LibraryComicSortOption sortOption,
  }) {
    final List<Comic> list = List<Comic>.from(comics);
    list.sort(sortOption.compare);
    return list;
  }
}
