/// 库页抽屉「年龄限制」筛选（漫画 / 系列 Tab 共用）。
///
/// 只保留枚举与存储契约；comic/series 语义方法见各自 `public/library_age_restriction_*.dart`。
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
}
