import 'dart:async';

import 'package:hentai_library/data/services/comic/v2/resource_types.dart';
import 'package:hentai_library/domain/enums/enums.dart';
import 'package:hentai_library/domain/value_objects/v2/library_comic_filter.dart';
import 'package:hentai_library/domain/value_objects/v2/library_tag_pick.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'comic_filter.g.dart';

@riverpod
class ComicFilterNotifier extends _$ComicFilterNotifier {
  Timer? _debounceTimer;

  @override
  LibraryComicFilter build() => LibraryComicFilter(showR18: false);

  void updateQuery(String? query) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      state = state.copyWith(query: query);
    });
  }

  void toggleR18(bool show) {
    state = state.copyWith(showR18: show);
  }

  void updateTags(Set<LibraryTagPick> tags) {
    state = state.copyWith(tagsAll: tags);
  }

  void updateTagsAny(Set<LibraryTagPick> tagsAny) {
    state = state.copyWith(tagsAny: tagsAny);
  }

  void updateTagsExclude(Set<LibraryTagPick> tagsExclude) {
    state = state.copyWith(tagsExclude: tagsExclude);
  }

  void updateTagFilter({
    Set<LibraryTagPick>? tags,
    Set<LibraryTagPick>? tagsAny,
    Set<LibraryTagPick>? tagsExclude,
  }) {
    state = state.copyWith(
      tagsAll: tags,
      tagsAny: tagsAny,
      tagsExclude: tagsExclude,
    );
  }

  void updateResourceTypes(Set<ResourceType> types) {
    state = state.copyWith(resourceTypes: types.isEmpty ? null : types);
  }

  void updateContentRatings(Set<ContentRating> ratings) {
    state = state.copyWith(contentRatings: ratings.isEmpty ? null : ratings);
  }

  void reset() => state = LibraryComicFilter(showR18: false);
}
