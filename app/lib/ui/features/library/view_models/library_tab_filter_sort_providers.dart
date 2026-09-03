import 'package:hentai_library/domain/library/library_age_restriction_filter.dart';
import 'package:hentai_library/domain/library/library_comic_sort_option.dart';
import 'package:hentai_library/domain/library/library_media_type_filter.dart';
import 'package:hentai_library/domain/library/library_metadata_filter_selection.dart';
import 'package:hentai_library/domain/library/library_series_sort_option.dart';
import 'package:hentai_library/domain/library/library_serialization_status_filter.dart';
import 'package:hentai_library/domain/models/enums.dart';
import 'package:hentai_library/ui/features/library/view_models/library_age_restriction_notifier.dart';
import 'package:hentai_library/ui/features/library/view_models/library_author_filter_notifier.dart';
import 'package:hentai_library/ui/features/library/view_models/library_catalog_selectors.dart';
import 'package:hentai_library/ui/features/library/view_models/library_include_set_filter_notifier.dart';
import 'package:hentai_library/ui/features/library/view_models/library_media_type_filter_notifier.dart';
import 'package:hentai_library/ui/features/library/view_models/library_serialization_status_filter_notifier.dart';
import 'package:hentai_library/ui/features/library/view_models/library_tag_filter_notifier.dart';
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
LibraryComicSortOption libraryActiveComicSortOption(Ref ref) {
  final LibraryDisplayTarget target = ref.watch(libraryDisplayTargetProvider);
  if (target != LibraryDisplayTarget.comics) {
    return kLibraryDefaultSortOption;
  }
  final AsyncValue<LibraryTabSortSettings> settingsAsync = ref.watch(
    libraryTabSortProvider,
  );
  return settingsAsync.maybeWhen(
    data: (LibraryTabSortSettings settings) => settings.comics,
    orElse: () => kLibraryDefaultSortOption,
  );
}

@Riverpod(keepAlive: true)
LibrarySeriesSortOption libraryActiveSeriesSortOption(Ref ref) {
  final LibraryDisplayTarget target = ref.watch(libraryDisplayTargetProvider);
  if (target != LibraryDisplayTarget.series) {
    return kLibraryDefaultSeriesSortOption;
  }
  final AsyncValue<LibraryTabSortSettings> settingsAsync = ref.watch(
    libraryTabSortProvider,
  );
  return settingsAsync.maybeWhen(
    data: (LibraryTabSortSettings settings) => settings.series,
    orElse: () => kLibraryDefaultSeriesSortOption,
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
LibrarySeriesSortOption librarySeriesTabSortOption(Ref ref) {
  final AsyncValue<LibraryTabSortSettings> settingsAsync = ref.watch(
    libraryTabSortProvider,
  );
  return settingsAsync.maybeWhen(
    data: (LibraryTabSortSettings settings) => settings.series,
    orElse: () => kLibraryDefaultSeriesSortOption,
  );
}

@Riverpod(keepAlive: true)
LibrarySerializationStatusFilter librarySeriesTabSerializationStatusFilter(
  Ref ref,
) {
  final AsyncValue<LibrarySerializationStatusFilter> settingsAsync = ref.watch(
    librarySerializationStatusFilterProvider,
  );
  return settingsAsync.maybeWhen(
    data: (LibrarySerializationStatusFilter filter) => filter,
    orElse: () => LibrarySerializationStatusFilter.unrestricted,
  );
}

@Riverpod(keepAlive: true)
LibraryMediaTypeFilterSelection libraryComicsTabMediaTypeFilter(Ref ref) {
  final AsyncValue<LibraryMediaTypeFilterSelection> selectionAsync = ref.watch(
    libraryMediaTypeFilterProvider,
  );
  return selectionAsync.maybeWhen(
    data: (LibraryMediaTypeFilterSelection selection) => selection,
    orElse: () => const LibraryMediaTypeFilterSelection(),
  );
}

@Riverpod(keepAlive: true)
LibraryMetadataFilterSelection libraryComicsTabTagFilter(Ref ref) {
  final AsyncValue<LibraryMetadataFilterSelection> selectionAsync = ref.watch(
    libraryTagFilterProvider,
  );
  return selectionAsync.maybeWhen(
    data: (LibraryMetadataFilterSelection selection) => selection,
    orElse: () => const LibraryMetadataFilterSelection(),
  );
}

@Riverpod(keepAlive: true)
LibraryMetadataFilterSelection libraryComicsTabAuthorFilter(Ref ref) {
  final AsyncValue<LibraryMetadataFilterSelection> selectionAsync = ref.watch(
    libraryAuthorFilterProvider,
  );
  return selectionAsync.maybeWhen(
    data: (LibraryMetadataFilterSelection selection) => selection,
    orElse: () => const LibraryMetadataFilterSelection(),
  );
}

@Riverpod(keepAlive: true)
Set<String> libraryComicsTabLanguageFilter(Ref ref) {
  return ref.watch(
    libraryIncludeSetFilterProvider(LibraryIncludeSetKind.language),
  );
}

@Riverpod(keepAlive: true)
Set<String> libraryComicsTabParodyFilter(Ref ref) {
  return ref.watch(
    libraryIncludeSetFilterProvider(LibraryIncludeSetKind.parody),
  );
}

@Riverpod(keepAlive: true)
Set<String> libraryComicsTabCharacterFilter(Ref ref) {
  return ref.watch(
    libraryIncludeSetFilterProvider(LibraryIncludeSetKind.character),
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
  final LibraryMediaTypeFilterSelection mediaTypeFilter = ref.watch(
    libraryComicsTabMediaTypeFilterProvider,
  );
  final LibraryMetadataFilterSelection tagFilter = ref.watch(
    libraryComicsTabTagFilterProvider,
  );
  final LibraryMetadataFilterSelection authorFilter = ref.watch(
    libraryComicsTabAuthorFilterProvider,
  );
  final Set<String> languageFilter = ref.watch(
    libraryComicsTabLanguageFilterProvider,
  );
  final Set<String> parodyFilter = ref.watch(
    libraryComicsTabParodyFilterProvider,
  );
  final Set<String> characterFilter = ref.watch(
    libraryComicsTabCharacterFilterProvider,
  );
  final LibrarySerializationStatusFilter serializationStatusFilter = ref.watch(
    librarySeriesTabSerializationStatusFilterProvider,
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
    mediaTypeFilter: mediaTypeFilter,
    tagFilter: tagFilter,
    authorFilter: authorFilter,
    languageFilter: languageFilter,
    parodyFilter: parodyFilter,
    characterFilter: characterFilter,
    serializationStatusFilter: serializationStatusFilter,
    sortSettings: sortSettings,
  );
}
