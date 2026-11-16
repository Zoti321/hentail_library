import 'package:hentai_library/shared/domain/library/library_age_restriction_filter.dart';

/// 年龄限制 → 系列分页 filter 标志（owner 规则，ADR-0035 / #488）。
extension LibraryAgeRestrictionSeriesX on LibraryAgeRestrictionFilter {
  ({bool showR18, bool r18Only}) seriesFilterFlags() => switch (this) {
    LibraryAgeRestrictionFilter.unrestricted => (showR18: true, r18Only: false),
    LibraryAgeRestrictionFilter.allAges => (showR18: false, r18Only: false),
    LibraryAgeRestrictionFilter.r18Only => (showR18: true, r18Only: true),
  };
}
