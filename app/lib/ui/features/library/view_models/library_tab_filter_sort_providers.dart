import 'package:hentai_library/domain/library/library_age_restriction_filter.dart';
import 'package:hentai_library/domain/library/library_comic_sort_option.dart';
import 'package:hentai_library/domain/library/library_prefer_library_root_series.dart';
import 'package:hentai_library/domain/library/library_serialization_status_filter.dart';
import 'package:hentai_library/domain/library/library_series_sort_option.dart';
import 'package:hentai_library/domain/models/enums.dart';
import 'package:hentai_library/ui/features/library/view_models/library_catalog_selectors.dart';
import 'package:hentai_library/ui/features/library/view_models/library_comic_filters_notifier.dart';
import 'package:hentai_library/ui/features/library/view_models/library_prefer_library_root_series_notifier.dart';
import 'package:hentai_library/ui/features/library/view_models/library_serialization_status_filter_notifier.dart';
import 'package:hentai_library/ui/features/library/view_models/library_series_age_restriction_notifier.dart';
import 'package:hentai_library/ui/features/library/view_models/library_series_filter_sort_settings.dart';
import 'package:hentai_library/ui/features/library/view_models/library_series_sort_notifier.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'library_tab_filter_sort_providers.g.dart';

/// 当前 Tab 生效的年龄限制：Comics 取自 [LibraryComicFiltersNotifier]，
/// Series 取自 [LibrarySeriesAgeRestrictionFilterNotifier]。
@Riverpod(keepAlive: true)
LibraryAgeRestrictionFilter libraryActiveAgeRestrictionFilter(Ref ref) {
  final LibraryDisplayTarget target = ref.watch(libraryDisplayTargetProvider);
  return switch (target) {
    LibraryDisplayTarget.comics => ref.watch(
      libraryComicFiltersProvider.select(
        (AsyncValue<LibraryComicFiltersState> state) =>
            state.value?.ageRestriction ??
            LibraryAgeRestrictionFilter.unrestricted,
      ),
    ),
    LibraryDisplayTarget.series => ref.watch(
      librarySeriesTabAgeRestrictionFilterProvider,
    ),
  };
}

@Riverpod(keepAlive: true)
LibraryComicSortOption libraryActiveComicSortOption(Ref ref) {
  final LibraryDisplayTarget target = ref.watch(libraryDisplayTargetProvider);
  if (target != LibraryDisplayTarget.comics) {
    return kLibraryDefaultSortOption;
  }
  return ref.watch(
    libraryComicFiltersProvider.select(
      (AsyncValue<LibraryComicFiltersState> state) =>
          state.value?.sortOption ?? kLibraryDefaultSortOption,
    ),
  );
}

@Riverpod(keepAlive: true)
LibrarySeriesSortOption libraryActiveSeriesSortOption(Ref ref) {
  final LibraryDisplayTarget target = ref.watch(libraryDisplayTargetProvider);
  if (target != LibraryDisplayTarget.series) {
    return kLibraryDefaultSeriesSortOption;
  }
  return ref.watch(librarySeriesTabSortOptionProvider);
}

@Riverpod(keepAlive: true)
LibraryAgeRestrictionFilter librarySeriesTabAgeRestrictionFilter(Ref ref) {
  final AsyncValue<LibraryAgeRestrictionFilter> settingsAsync = ref.watch(
    librarySeriesAgeRestrictionFilterProvider,
  );
  return settingsAsync.maybeWhen(
    data: (LibraryAgeRestrictionFilter filter) => filter,
    orElse: () => LibraryAgeRestrictionFilter.unrestricted,
  );
}

@Riverpod(keepAlive: true)
LibrarySeriesSortOption librarySeriesTabSortOption(Ref ref) {
  final AsyncValue<LibrarySeriesSortOption> settingsAsync = ref.watch(
    librarySeriesSortProvider,
  );
  return settingsAsync.maybeWhen(
    data: (LibrarySeriesSortOption option) => option,
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
bool librarySeriesTabPreferLibraryRootSeries(Ref ref) {
  final AsyncValue<bool> settingsAsync = ref.watch(
    libraryPreferLibraryRootSeriesProvider,
  );
  return settingsAsync.maybeWhen(
    data: (bool enabled) => enabled,
    orElse: () => LibraryPreferLibraryRootSeries.defaultValue,
  );
}

@Riverpod(keepAlive: true)
bool libraryActiveFilterSortIsCustomized(Ref ref) {
  final LibraryDisplayTarget target = ref.watch(libraryDisplayTargetProvider);
  return switch (target) {
    LibraryDisplayTarget.comics => ref.watch(
      libraryComicFiltersIsCustomizedProvider,
    ),
    LibraryDisplayTarget.series => isLibrarySeriesFilterSortCustomized(
      ageRestriction: ref.watch(librarySeriesTabAgeRestrictionFilterProvider),
      serializationStatusFilter: ref.watch(
        librarySeriesTabSerializationStatusFilterProvider,
      ),
      preferLibraryRootSeries: ref.watch(
        librarySeriesTabPreferLibraryRootSeriesProvider,
      ),
      sortOption: ref.watch(librarySeriesTabSortOptionProvider),
    ),
  };
}
