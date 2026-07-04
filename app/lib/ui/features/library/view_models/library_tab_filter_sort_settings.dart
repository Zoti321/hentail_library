import 'package:hentai_library/domain/library/library_age_restriction_filter.dart';
import 'package:hentai_library/domain/library/library_comic_sort_option.dart';
import 'package:hentai_library/domain/models/enums.dart';

typedef LibraryTabAgeRestrictionSettings = ({
  LibraryAgeRestrictionFilter comics,
  LibraryAgeRestrictionFilter series,
});

typedef LibraryTabSortSettings = ({
  LibraryComicSortOption comics,
  LibraryComicSortOption series,
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

LibraryComicSortOption sortOptionForTarget(
  LibraryTabSortSettings settings,
  LibraryDisplayTarget target,
) {
  return switch (target) {
    LibraryDisplayTarget.comics => settings.comics,
    LibraryDisplayTarget.series => settings.series,
  };
}

LibraryTabAgeRestrictionSettings copyAgeRestrictionForTarget(
  LibraryTabAgeRestrictionSettings settings,
  LibraryDisplayTarget target,
  LibraryAgeRestrictionFilter value,
) {
  return switch (target) {
    LibraryDisplayTarget.comics => (
      comics: value,
      series: settings.series,
    ),
    LibraryDisplayTarget.series => (
      comics: settings.comics,
      series: value,
    ),
  };
}

LibraryTabSortSettings copySortForTarget(
  LibraryTabSortSettings settings,
  LibraryDisplayTarget target,
  LibraryComicSortOption value,
) {
  return switch (target) {
    LibraryDisplayTarget.comics => (
      comics: value,
      series: settings.series,
    ),
    LibraryDisplayTarget.series => (
      comics: settings.comics,
      series: value,
    ),
  };
}

final LibraryComicSortOption kLibraryDefaultSortOption = LibraryComicSortOption();

bool isLibraryFilterSortCustomized({
  required LibraryAgeRestrictionFilter ageRestriction,
  required LibraryComicSortOption sortOption,
}) {
  return ageRestriction != LibraryAgeRestrictionFilter.unrestricted ||
      sortOption.field != kLibraryDefaultSortOption.field ||
      sortOption.descending != kLibraryDefaultSortOption.descending;
}

bool isLibraryFilterSortCustomizedForTarget({
  required LibraryDisplayTarget target,
  required LibraryTabAgeRestrictionSettings ageSettings,
  required LibraryTabSortSettings sortSettings,
}) {
  return isLibraryFilterSortCustomized(
    ageRestriction: ageRestrictionForTarget(ageSettings, target),
    sortOption: sortOptionForTarget(sortSettings, target),
  );
}
