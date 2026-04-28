import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hentai_library/model/entity/comic/comic.dart';

part 'library_comic_sort_option.freezed.dart';

enum LibraryComicSortField { title }

@freezed
abstract class LibraryComicSortOption with _$LibraryComicSortOption {
  factory LibraryComicSortOption({
    @Default(LibraryComicSortField.title) LibraryComicSortField field,
    @Default(false) bool descending,
  }) = _LibraryComicSortOption;

  const LibraryComicSortOption._();

  int compare(Comic a, Comic b) {
    int result;
    switch (field) {
      case LibraryComicSortField.title:
        result = a.title.compareTo(b.title);
    }
    return descending ? -result : result;
  }
}
