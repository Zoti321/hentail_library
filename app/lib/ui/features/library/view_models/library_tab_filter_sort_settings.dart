import 'package:hentai_library/domain/library/library_age_restriction_filter.dart';
import 'package:hentai_library/domain/library/library_comic_sort_option.dart';
import 'package:hentai_library/domain/library/library_media_type_filter.dart';
import 'package:hentai_library/domain/library/library_metadata_filter_selection.dart';
import 'package:hentai_library/domain/library/library_series_sort_option.dart';
import 'package:hentai_library/domain/library/library_serialization_status_filter.dart';
import 'package:hentai_library/domain/models/enums.dart';

typedef LibraryTabAgeRestrictionSettings = ({
  LibraryAgeRestrictionFilter comics,
  LibraryAgeRestrictionFilter series,
});

typedef LibraryTabSortSettings = ({
  LibraryComicSortOption comics,
  LibrarySeriesSortOption series,
});

LibraryAgeRestrictionFilter ageRestrictionForTarget(
  LibraryTabAgeRestrictionSettings settings,
  LibraryDisplayTarget target,
) {
  return switch (target) {
    LibraryDisplayTarget.comics => settings.comics,
    LibraryDisplayTarget.series => settings.series,
  };
}

LibraryComicSortOption comicSortOptionForTarget(
  LibraryTabSortSettings settings,
  LibraryDisplayTarget target,
) {
  return switch (target) {
    LibraryDisplayTarget.comics => settings.comics,
    LibraryDisplayTarget.series => kLibraryDefaultSortOption,
  };
}

LibrarySeriesSortOption seriesSortOptionForTarget(
  LibraryTabSortSettings settings,
  LibraryDisplayTarget target,
) {
  return switch (target) {
    LibraryDisplayTarget.comics => kLibraryDefaultSeriesSortOption,
    LibraryDisplayTarget.series => settings.series,
  };
}

LibraryTabAgeRestrictionSettings copyAgeRestrictionForTarget(
  LibraryTabAgeRestrictionSettings settings,
  LibraryDisplayTarget target,
  LibraryAgeRestrictionFilter value,
) {
  return switch (target) {
    LibraryDisplayTarget.comics => (comics: value, series: settings.series),
    LibraryDisplayTarget.series => (comics: settings.comics, series: value),
  };
}

LibraryTabSortSettings copyComicSortForTarget(
  LibraryTabSortSettings settings,
  LibraryComicSortOption value,
) {
  return (comics: value, series: settings.series);
}

LibraryTabSortSettings copySeriesSortForTarget(
  LibraryTabSortSettings settings,
  LibrarySeriesSortOption value,
) {
  return (comics: settings.comics, series: value);
}

final LibraryComicSortOption kLibraryDefaultSortOption =
    LibraryComicSortOption();

bool isLibraryComicFilterSortCustomized({
  required LibraryAgeRestrictionFilter ageRestriction,
  required LibraryMediaTypeFilterSelection mediaTypeFilter,
  required LibraryMetadataFilterSelection tagFilter,
  required LibraryMetadataFilterSelection authorFilter,
  required Set<String> languageFilter,
  required Set<String> parodyFilter,
  required Set<String> characterFilter,
  required LibraryComicSortOption sortOption,
}) {
  return ageRestriction != LibraryAgeRestrictionFilter.unrestricted ||
      mediaTypeFilter.isActive ||
      tagFilter.isActive ||
      authorFilter.isActive ||
      languageFilter.isNotEmpty ||
      parodyFilter.isNotEmpty ||
      characterFilter.isNotEmpty ||
      sortOption.field != kLibraryDefaultSortOption.field ||
      sortOption.descending != kLibraryDefaultSortOption.descending;
}

bool isLibrarySeriesFilterSortCustomized({
  required LibraryAgeRestrictionFilter ageRestriction,
  required LibrarySerializationStatusFilter serializationStatusFilter,
  required LibrarySeriesSortOption sortOption,
}) {
  return ageRestriction != LibraryAgeRestrictionFilter.unrestricted ||
      serializationStatusFilter !=
          LibrarySerializationStatusFilter.unrestricted ||
      sortOption.field != kLibraryDefaultSeriesSortOption.field ||
      sortOption.descending != kLibraryDefaultSeriesSortOption.descending;
}

bool isLibraryFilterSortCustomizedForTarget({
  required LibraryDisplayTarget target,
  required LibraryTabAgeRestrictionSettings ageSettings,
  required LibraryMediaTypeFilterSelection mediaTypeFilter,
  required LibraryMetadataFilterSelection tagFilter,
  required LibraryMetadataFilterSelection authorFilter,
  required Set<String> languageFilter,
  required Set<String> parodyFilter,
  required Set<String> characterFilter,
  required LibrarySerializationStatusFilter serializationStatusFilter,
  required LibraryTabSortSettings sortSettings,
}) {
  return switch (target) {
    LibraryDisplayTarget.comics => isLibraryComicFilterSortCustomized(
      ageRestriction: ageSettings.comics,
      mediaTypeFilter: mediaTypeFilter,
      tagFilter: tagFilter,
      authorFilter: authorFilter,
      languageFilter: languageFilter,
      parodyFilter: parodyFilter,
      characterFilter: characterFilter,
      sortOption: sortSettings.comics,
    ),
    LibraryDisplayTarget.series => isLibrarySeriesFilterSortCustomized(
      ageRestriction: ageSettings.series,
      serializationStatusFilter: serializationStatusFilter,
      sortOption: sortSettings.series,
    ),
  };
}
