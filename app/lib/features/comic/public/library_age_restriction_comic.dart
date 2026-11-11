import 'package:hentai_library/shared/domain/library/library_age_restriction_filter.dart';
import 'package:hentai_library/shared/domain/models/enums.dart';

/// 年龄限制 → 漫画分页 filter 语义（owner 规则，ADR-0035 / #488）。
extension LibraryAgeRestrictionComicX on LibraryAgeRestrictionFilter {
  /// 漫画分页 filter：是否允许 R18（与 `contentRatings` 组合）。
  bool comicShowR18() => this != LibraryAgeRestrictionFilter.allAges;

  Set<ContentRating>? comicContentRatings() => switch (this) {
    LibraryAgeRestrictionFilter.r18Only => const <ContentRating>{
      ContentRating.r18,
    },
    _ => null,
  };
}
