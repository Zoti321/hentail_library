import 'package:hentai_library/domain/enums/enums.dart';
import 'package:hentai_library/domain/value_objects/comic_sort_option.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'comic_sort_option.g.dart';

@riverpod
class ComicSortOptionNotifier extends _$ComicSortOptionNotifier {
  @override
  ComicSortOption build() => ComicSortOption();

  void toggleDescenging(bool descending) {
    state = state.copyWith(descending: descending);
  }

  void updateSortType(ComicSortType type) {
    state = state.copyWith(field: type);
  }

  void reset() {
    state = ComicSortOption();
  }
}
