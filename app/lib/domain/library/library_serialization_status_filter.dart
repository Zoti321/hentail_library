/// 库页系列 Tab 抽屉「连载状态」筛选（单选；无选中即 [unrestricted]）。
enum LibrarySerializationStatusFilter {
  /// 不限：显示全部连载状态。
  unrestricted,

  ongoing,
  ended,
  hiatus,
  unknown;

  static const String storageKey = 'library_serialization_status_filter_series';

  static LibrarySerializationStatusFilter fromStorage(String? raw) {
    return LibrarySerializationStatusFilter.values.asNameMap()[raw] ??
        LibrarySerializationStatusFilter.unrestricted;
  }

  /// 抽屉 UI 可选项（不含「不限」；无选中即 [unrestricted]）。
  static const List<LibrarySerializationStatusFilter> selectableOptions =
      <LibrarySerializationStatusFilter>[
        LibrarySerializationStatusFilter.ongoing,
        LibrarySerializationStatusFilter.ended,
        LibrarySerializationStatusFilter.hiatus,
        LibrarySerializationStatusFilter.unknown,
      ];

  /// 系列分页 filter；不限时返回 `null`。
  String? seriesSerializationStatus() => switch (this) {
    LibrarySerializationStatusFilter.unrestricted => null,
    LibrarySerializationStatusFilter.ongoing => 'ongoing',
    LibrarySerializationStatusFilter.ended => 'ended',
    LibrarySerializationStatusFilter.hiatus => 'hiatus',
    LibrarySerializationStatusFilter.unknown => 'unknown',
  };
}
