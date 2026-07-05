import 'package:hentai_library/domain/library/library_age_restriction_filter.dart';
import 'package:hentai_library/domain/library/library_comic_sort_option.dart';
import 'package:hentai_library/domain/models/enums.dart';
import 'package:hentai_library/ui/features/library/view_models/library_age_restriction_notifier.dart';
import 'package:hentai_library/ui/features/library/view_models/library_catalog_selectors.dart';
import 'package:hentai_library/ui/features/library/view_models/library_tab_filter_sort_settings.dart';
import 'package:hentai_library/ui/features/library/view_models/library_tab_sort_notifier.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'library_tab_filter_sort_providers.g.dart';

@Riverpod(keepAlive: true)
LibraryAgeRestrictionFilter libraryActiveAgeRestrictionFilter(Ref ref) {
  final LibraryDisplayTarget target = ref.watch(libraryDisplayTargetProvider);
  final AsyncValue<LibraryTabAgeRestrictionSettings> settingsAsync = ref.watch(
    libraryAgeRestrictionFilterProvider,
  );
  return settingsAsync.maybeWhen(
    data: (LibraryTabAgeRestrictionSettings settings) =>
        ageRestrictionForTarget(settings, target),
    orElse: () => LibraryAgeRestrictionFilter.unrestricted,
  );
}

@Riverpod(keepAlive: true)
LibraryComicSortOption libraryActiveSortOption(Ref ref) {
  final LibraryDisplayTarget target = ref.watch(libraryDisplayTargetProvider);
  final AsyncValue<LibraryTabSortSettings> settingsAsync = ref.watch(
    libraryTabSortProvider,
  );
  return settingsAsync.maybeWhen(
    data: (LibraryTabSortSettings settings) =>
        sortOptionForTarget(settings, target),
    orElse: () => kLibraryDefaultSortOption,
  );
}

@Riverpod(keepAlive: true)
LibraryAgeRestrictionFilter libraryComicsTabAgeRestrictionFilter(Ref ref) {
  final AsyncValue<LibraryTabAgeRestrictionSettings> settingsAsync = ref.watch(
    libraryAgeRestrictionFilterProvider,
  );
  return settingsAsync.maybeWhen(
    data: (LibraryTabAgeRestrictionSettings settings) => settings.comics,
    orElse: () => LibraryAgeRestrictionFilter.unrestricted,
  );
}

@Riverpod(keepAlive: true)
LibraryComicSortOption libraryComicsTabSortOption(Ref ref) {
  final AsyncValue<LibraryTabSortSettings> settingsAsync = ref.watch(
    libraryTabSortProvider,
  );
  return settingsAsync.maybeWhen(
    data: (LibraryTabSortSettings settings) => settings.comics,
    orElse: () => kLibraryDefaultSortOption,
  );
}

@Riverpod(keepAlive: true)
LibraryAgeRestrictionFilter librarySeriesTabAgeRestrictionFilter(Ref ref) {
  final AsyncValue<LibraryTabAgeRestrictionSettings> settingsAsync = ref.watch(
    libraryAgeRestrictionFilterProvider,
  );
  return settingsAsync.maybeWhen(
    data: (LibraryTabAgeRestrictionSettings settings) => settings.series,
    orElse: () => LibraryAgeRestrictionFilter.unrestricted,
  );
}

@Riverpod(keepAlive: true)
LibraryComicSortOption librarySeriesTabSortOption(Ref ref) {
  final AsyncValue<LibraryTabSortSettings> settingsAsync = ref.watch(
    libraryTabSortProvider,
  );
  return settingsAsync.maybeWhen(
    data: (LibraryTabSortSettings settings) => settings.series,
    orElse: () => kLibraryDefaultSortOption,
  );
}

@Riverpod(keepAlive: true)
bool libraryActiveFilterSortIsCustomized(Ref ref) {
  final LibraryDisplayTarget target = ref.watch(libraryDisplayTargetProvider);
  final AsyncValue<LibraryTabAgeRestrictionSettings> ageAsync = ref.watch(
    libraryAgeRestrictionFilterProvider,
  );
  final AsyncValue<LibraryTabSortSettings> sortAsync = ref.watch(
    libraryTabSortProvider,
  );
  final LibraryTabAgeRestrictionSettings ageSettings = ageAsync.maybeWhen(
    data: (LibraryTabAgeRestrictionSettings settings) => settings,
    orElse: () => kDefaultLibraryTabAgeRestrictionSettings,
  );
  final LibraryTabSortSettings sortSettings = sortAsync.maybeWhen(
    data: (LibraryTabSortSettings settings) => settings,
    orElse: () => kDefaultLibraryTabSortSettings,
  );
  return isLibraryFilterSortCustomizedForTarget(
    target: target,
    ageSettings: ageSettings,
    sortSettings: sortSettings,
  );
}
