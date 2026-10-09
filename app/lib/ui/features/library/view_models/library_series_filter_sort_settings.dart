import 'package:hentai_library/domain/library/library_age_restriction_filter.dart';
import 'package:hentai_library/domain/library/library_prefer_library_root_series.dart';
import 'package:hentai_library/domain/library/library_serialization_status_filter.dart';
import 'package:hentai_library/domain/library/library_series_sort_option.dart';

/// Series Tab 是否含有非默认筛选 / 排序。
///
/// Comics 侧的对应判断由 [libraryComicFiltersIsCustomizedProvider] 提供。
bool isLibrarySeriesFilterSortCustomized({
  required LibraryAgeRestrictionFilter ageRestriction,
  required LibrarySerializationStatusFilter serializationStatusFilter,
  required LibrarySeriesSortOption sortOption,
  bool preferLibraryRootSeries = LibraryPreferLibraryRootSeries.defaultValue,
}) {
  return ageRestriction != LibraryAgeRestrictionFilter.unrestricted ||
      serializationStatusFilter !=
          LibrarySerializationStatusFilter.unrestricted ||
      preferLibraryRootSeries != LibraryPreferLibraryRootSeries.defaultValue ||
      sortOption.field != kLibraryDefaultSeriesSortOption.field ||
      sortOption.descending != kLibraryDefaultSeriesSortOption.descending;
}
