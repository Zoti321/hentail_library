/// 库页抽屉「年龄限制」筛选（漫画 / 系列 Tab 共用）。
///
/// 只保留枚举语义与存储解码；comic/series 语义方法见各自
/// `public/library_age_restriction_*.dart`。存储键属 browse 持久化实现，
/// 见 `features/library_browse/.../library_comic_filters_persistence.dart`。
enum LibraryAgeRestrictionFilter {
  /// 不限：显示全部分级。
  unrestricted,

  /// 全年龄：仅 safe + unknown。
  allAges,

  /// 仅 R18。
  r18Only;

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
}
