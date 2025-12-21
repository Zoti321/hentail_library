import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hentai_library/domain/enums/enums.dart';

import '../entity/entities.dart';

part 'comic_sort_option.freezed.dart';

@freezed
abstract class ComicSortOption with _$ComicSortOption {
  factory ComicSortOption({
    @Default(ComicSortType.title) ComicSortType field,
    @Default(false) bool descending,
  }) = _ComicSortOption;

  const ComicSortOption._();

  int compare(Comic a, Comic b) {
    int result;
    switch (field) {
      case ComicSortType.title:
        result = a.title.compareTo(b.title);
      case ComicSortType.lastUpdated:
        result = _compareDate(a.lastUpdatedAt, b.lastUpdatedAt);
      case ComicSortType.firstPublished:
        result = _compareDate(a.firstPublishedAt, b.firstPublishedAt);
      case ComicSortType.totalViews:
        result = (a.totalViews ?? 0).compareTo(b.totalViews ?? 0);
    }
    return descending ? -result : result;
  }

  int _compareDate(DateTime? a, DateTime? b) {
    if (a == null && b == null) return 0;
    if (a == null) return 1;
    if (b == null) return -1;
    return a.compareTo(b);
  }
}
