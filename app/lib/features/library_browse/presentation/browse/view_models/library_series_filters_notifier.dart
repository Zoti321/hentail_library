import 'package:hentai_library/features/library_browse/domain/browse/library_series_browse_preferences.dart';
import 'package:hentai_library/features/library_browse/domain/browse/library_browse_preferences_repository.dart';
import 'package:hentai_library/features/library_browse/presentation/providers/library_browse_preferences_provider.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/features/app_settings/public/app_settings_cross_feature_types.dart';
import 'package:hentai_library/features/app_settings/public/providers/app_settings_providers.dart';
import 'package:hentai_library/features/library_browse/domain/browse/library_age_restriction_filter.dart';
import 'package:hentai_library/features/library_browse/presentation/browse/view_models/library_query_intent.dart';
import 'package:hentai_library/features/library_browse/presentation/browse/view_models/library_query_intent_notifier.dart';
import 'package:hentai_library/shared/presentation/providers/browse_library_scope_providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:hentai_library/features/series/public.dart';
import 'package:hentai_library/features/library_browse/presentation/browse/models/series_catalog_query_assembly.dart';

part 'library_series_filters_notifier.g.dart';

@Riverpod(keepAlive: true)
class LibrarySeriesFiltersNotifier extends _$LibrarySeriesFiltersNotifier {
  LibraryBrowsePreferencesRepository get _preferences =>
      ref.read(libraryBrowsePreferencesRepositoryProvider);

  @override
  Future<LibrarySeriesBrowsePreferences> build() =>
      _preferences.loadSeriesFilters();

  Future<void> setAgeRestriction(LibraryAgeRestrictionFilter filter) async {
    _apply((await future).copyWith(ageRestriction: filter));
    await _preferences.saveSeriesAgeRestriction(filter);
  }

  Future<void> toggleAgeRestrictionOption(
    LibraryAgeRestrictionFilter option,
  ) async {
    final LibraryAgeRestrictionFilter existing = (await future).ageRestriction;
    await setAgeRestriction(
      existing == option ? LibraryAgeRestrictionFilter.unrestricted : option,
    );
  }

  Future<void> setSerializationStatusFilter(
    LibrarySerializationStatusFilter filter,
  ) async {
    _apply((await future).copyWith(serializationStatusFilter: filter));
    await _preferences.saveSeriesSerializationStatus(filter);
  }

  Future<void> toggleSerializationStatusFilterOption(
    LibrarySerializationStatusFilter option,
  ) async {
    final LibrarySerializationStatusFilter existing =
        (await future).serializationStatusFilter;
    await setSerializationStatusFilter(
      existing == option
          ? LibrarySerializationStatusFilter.unrestricted
          : option,
    );
  }

  Future<void> setGrouping(LibrarySeriesGrouping grouping) async {
    _apply((await future).copyWith(grouping: grouping));
    await _preferences.saveSeriesGrouping(grouping);
  }

  Future<void> setSortField(LibrarySeriesSortField field) async {
    final LibrarySeriesSortOption existing = (await future).sortOption;
    final LibrarySeriesSortOption next = existing.field == field
        ? existing.copyWith(descending: !existing.descending)
        : LibrarySeriesSortOption(field: field);
    _apply((await future).copyWith(sortOption: next));
    await _preferences.saveSeriesSort(next);
  }

  Future<void> resetAll() async {
    await _preferences.resetSeriesFilters();
    _apply(LibrarySeriesBrowsePreferences.defaults);
  }

  void _apply(LibrarySeriesBrowsePreferences updated) {
    state = AsyncData<LibrarySeriesBrowsePreferences>(updated);
  }
}

const SeriesCatalogQueryAssembly _seriesProjection =
    SeriesCatalogQueryAssembly();

final Provider<bool> librarySeriesFiltersIsCustomizedProvider = Provider<bool>((
  Ref ref,
) {
  final LibrarySeriesBrowsePreferences filters =
      ref.watch(librarySeriesFiltersProvider).value ??
      LibrarySeriesBrowsePreferences.defaults;
  return filters != LibrarySeriesBrowsePreferences.defaults;
});

final Provider<LibrarySeriesFilter> librarySeriesFiltersQueryProvider =
    Provider<LibrarySeriesFilter>((Ref ref) {
      final LibrarySeriesBrowsePreferences filters =
          ref.watch(librarySeriesFiltersProvider).value ??
          LibrarySeriesBrowsePreferences.defaults;
      final String keyword = ref.watch(
        libraryQueryIntentProvider.select(
          (LibraryQueryIntent intent) => intent.keyword,
        ),
      );
      final bool preferLibraryRootSeries = ref.watch(
        appSettingsProvider.select(
          (AsyncValue<AppSetting> async) =>
              async.asData?.value.preferLibraryRootSeries ?? true,
        ),
      );
      final String? libraryId = ref.watch(browseLibraryIdProvider);
      return _seriesProjection.buildListFilter(
        ageRestriction: filters.ageRestriction,
        serializationStatusFilter: filters.serializationStatusFilter,
        preferLibraryRootSeries: preferLibraryRootSeries,
        keyword: keyword,
        libraryId: libraryId,
      );
    });

final Provider<LibrarySeriesGrouping> librarySeriesTabGroupingProvider =
    Provider<LibrarySeriesGrouping>((Ref ref) {
      return ref.watch(
        librarySeriesFiltersProvider.select(
          (AsyncValue<LibrarySeriesBrowsePreferences> state) =>
              state.value?.grouping ?? LibrarySeriesGrouping.defaultValue,
        ),
      );
    });
