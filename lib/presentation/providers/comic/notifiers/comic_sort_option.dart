import 'package:hentai_library/domain/value_objects/v2/library_comic_sort_option.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'comic_sort_option.g.dart';

@riverpod
class ComicSortOptionNotifier extends _$ComicSortOptionNotifier {
  @override
  LibraryComicSortOption build() => LibraryComicSortOption();

  void toggleDescenging(bool descending) {
    state = state.copyWith(descending: descending);
  }

  void updateSortField(LibraryComicSortField field) {
    state = state.copyWith(field: field);
  }

  void reset() {
    state = LibraryComicSortOption();
  }
}
