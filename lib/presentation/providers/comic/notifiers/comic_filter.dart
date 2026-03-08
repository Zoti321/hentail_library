import 'dart:async';

import 'package:hentai_library/domain/entity/comic/category_tag.dart';
import 'package:hentai_library/domain/enums/enums.dart';
import 'package:hentai_library/domain/value_objects/comic_filter.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'comic_filter.g.dart';

@riverpod
class ComicFilterNotifier extends _$ComicFilterNotifier {
  Timer? _debounceTimer;

  @override
  ComicFilter build() {
    // 默认筛选配置
    return ComicFilter(showR18: false);
  }

  // 快捷关键词修改方法
  void updateQuery(String? query) {
    _debounceTimer?.cancel();

    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      state = state.copyWith(query: query);
    });
  }

  void toggleR18(bool show) {
    state = state.copyWith(showR18: show);
  }

  void updateTags(Set<CategoryTag> tags) {
    state = state.copyWith(tags: tags);
  }

  void updateTagsAny(Set<CategoryTag> tagsAny) {
    state = state.copyWith(tagsAny: tagsAny);
  }

  void updateTagsExclude(Set<CategoryTag> tagsExclude) {
    state = state.copyWith(tagsExclude: tagsExclude);
  }

  /// 一次性写入三组标签（用于标签选择面板确认）。
  void updateTagFilter({
    Set<CategoryTag>? tags,
    Set<CategoryTag>? tagsAny,
    Set<CategoryTag>? tagsExclude,
  }) {
    state = state.copyWith(
      tags: tags,
      tagsAny: tagsAny,
      tagsExclude: tagsExclude,
    );
  }

  void updateImageSourceType(Set<ComicImageSourceType> imageSourceTypes) {
    state = state.copyWith(imageSourceTypes: imageSourceTypes);
  }

  void reset() => state = ComicFilter(showR18: false);
}
