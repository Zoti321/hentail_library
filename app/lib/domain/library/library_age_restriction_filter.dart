import 'package:hentai_library/domain/models/enums.dart';

/// 库页抽屉「年龄限制」筛选（漫画 / 系列 Tab 共用）。
enum LibraryAgeRestrictionFilter {
  /// 不限：显示全部分级。
  unrestricted,

  /// 全年龄：仅 safe + unknown。
  allAges,

  /// 仅 R18。
  r18Only;

  static const String storageKey = 'library_age_restriction_filter';

  static LibraryAgeRestrictionFilter fromStorage(String? raw) {
    return LibraryAgeRestrictionFilter.values.asNameMap()[raw] ??
        LibraryAgeRestrictionFilter.unrestricted;
  }

  /// 抽屉 UI 可选项（不含「不限」；无选中即 [unrestricted]）。
  static const List<LibraryAgeRestrictionFilter> selectableOptions =
      <LibraryAgeRestrictionFilter>[
        LibraryAgeRestrictionFilter.allAges,
        LibraryAgeRestrictionFilter.r18Only,
      ];

  String get label => switch (this) {
    LibraryAgeRestrictionFilter.unrestricted => '不限',
    LibraryAgeRestrictionFilter.allAges => '全年龄',
    LibraryAgeRestrictionFilter.r18Only => 'R18',
  };

  /// 漫画分页 filter：是否允许 R18（与 `contentRatings` 组合）。
  bool comicShowR18() => this != LibraryAgeRestrictionFilter.allAges;

  Set<ContentRating>? comicContentRatings() => switch (this) {
    LibraryAgeRestrictionFilter.r18Only => const <ContentRating>{
      ContentRating.r18,
    },
    _ => null,
  };

  /// 系列分页 filter 标志。
  ({bool showR18, bool r18Only}) seriesFilterFlags() => switch (this) {
    LibraryAgeRestrictionFilter.unrestricted => (showR18: true, r18Only: false),
    LibraryAgeRestrictionFilter.allAges => (showR18: false, r18Only: false),
    LibraryAgeRestrictionFilter.r18Only => (showR18: true, r18Only: true),
  };
}
