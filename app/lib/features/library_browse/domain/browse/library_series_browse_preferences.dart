import 'package:hentai_library/features/series/public/library_series_browse_rules.dart';
import 'package:hentai_library/features/library_browse/domain/browse/library_age_restriction_filter.dart';

/// Series Tab 的 Library browse preference：单一不可变值对象，维度落盘。
class LibrarySeriesBrowsePreferences {
  const LibrarySeriesBrowsePreferences({
    this.ageRestriction = LibraryAgeRestrictionFilter.unrestricted,
    this.serializationStatusFilter =
        LibrarySerializationStatusFilter.unrestricted,
    this.grouping = LibrarySeriesGrouping.defaultValue,
    this.sortOption = kLibraryDefaultSeriesSortOption,
  });

  static const LibrarySeriesBrowsePreferences defaults =
      LibrarySeriesBrowsePreferences();

  final LibraryAgeRestrictionFilter ageRestriction;
  final LibrarySerializationStatusFilter serializationStatusFilter;
  final LibrarySeriesGrouping grouping;
  final LibrarySeriesSortOption sortOption;

  LibrarySeriesBrowsePreferences copyWith({
    LibraryAgeRestrictionFilter? ageRestriction,
    LibrarySerializationStatusFilter? serializationStatusFilter,
    LibrarySeriesGrouping? grouping,
    LibrarySeriesSortOption? sortOption,
  }) {
    return LibrarySeriesBrowsePreferences(
      ageRestriction: ageRestriction ?? this.ageRestriction,
      serializationStatusFilter:
          serializationStatusFilter ?? this.serializationStatusFilter,
      grouping: grouping ?? this.grouping,
      sortOption: sortOption ?? this.sortOption,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is LibrarySeriesBrowsePreferences &&
            other.ageRestriction == ageRestriction &&
            other.serializationStatusFilter == serializationStatusFilter &&
            other.grouping == grouping &&
            other.sortOption == sortOption;
  }

  @override
  int get hashCode => Object.hash(
    ageRestriction,
    serializationStatusFilter,
    grouping,
    sortOption,
  );
}
