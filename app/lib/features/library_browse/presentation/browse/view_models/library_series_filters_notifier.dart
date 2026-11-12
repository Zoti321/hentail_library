import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/features/app_settings/public/app_settings_cross_feature_types.dart';
import 'package:hentai_library/features/app_settings/public/di/app_settings_providers.dart';
import 'package:hentai_library/features/library_browse/domain/browse/library_age_restriction_filter.dart';
import 'package:hentai_library/features/library_browse/presentation/browse/view_models/library_comic_filters_notifier.dart';
import 'package:hentai_library/features/library_browse/presentation/browse/view_models/library_query_intent.dart';
import 'package:hentai_library/features/library_browse/presentation/browse/view_models/library_query_intent_notifier.dart';
import 'package:hentai_library/shared/di/browse_library_scope_providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hentai_library/features/series/public.dart';
import 'package:hentai_library/features/library_browse/presentation/browse/models/series_catalog_query_assembly.dart';

part 'library_series_filters_notifier.g.dart';

/// Series Tab 的 Library browse preference：单一不可变值对象，维度落盘。
class LibrarySeriesFiltersState {
  const LibrarySeriesFiltersState({
    this.ageRestriction = LibraryAgeRestrictionFilter.unrestricted,
    this.serializationStatusFilter =
        LibrarySerializationStatusFilter.unrestricted,
    this.grouping = LibrarySeriesGrouping.defaultValue,
    this.sortOption = kLibraryDefaultSeriesSortOption,
  });

  static const LibrarySeriesFiltersState defaults = LibrarySeriesFiltersState();

  final LibraryAgeRestrictionFilter ageRestriction;
  final LibrarySerializationStatusFilter serializationStatusFilter;
  final LibrarySeriesGrouping grouping;
  final LibrarySeriesSortOption sortOption;

  LibrarySeriesFiltersState copyWith({
    LibraryAgeRestrictionFilter? ageRestriction,
    LibrarySerializationStatusFilter? serializationStatusFilter,
    LibrarySeriesGrouping? grouping,
    LibrarySeriesSortOption? sortOption,
  }) {
    return LibrarySeriesFiltersState(
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
        other is LibrarySeriesFiltersState &&
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

String encodeLibrarySeriesSortOption(LibrarySeriesSortOption option) {
  return '${option.field.name},${option.descending}';
}

LibrarySeriesSortOption decodeLibrarySeriesSortOption(String? raw) {
  if (raw == null || raw.isEmpty) {
    return kLibraryDefaultSeriesSortOption;
  }
  final List<String> parts = raw.split(',');
  if (parts.length != 2) {
    return kLibraryDefaultSeriesSortOption;
  }
  final String fieldName = parts[0] == 'title' ? 'name' : parts[0];
  final LibrarySeriesSortField? field = LibrarySeriesSortField.values
      .asNameMap()[fieldName];
  if (field == null) {
    return kLibraryDefaultSeriesSortOption;
  }
  return LibrarySeriesSortOption(field: field, descending: parts[1] == 'true');
}

@Riverpod(keepAlive: true)
class LibrarySeriesFiltersNotifier extends _$LibrarySeriesFiltersNotifier {
  static const String _ageStorageKey = kLibrarySeriesAgeRestrictionStorageKey;
  static const String _serializationStatusStorageKey =
      LibrarySerializationStatusFilter.storageKey;
  static const String _sortStorageKey = 'library_sort_series';

  @override
  Future<LibrarySeriesFiltersState> build() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await migrateLegacyLibraryAgeRestriction(prefs);
    return LibrarySeriesFiltersState(
      ageRestriction: LibraryAgeRestrictionFilter.fromStorage(
        prefs.getString(_ageStorageKey),
      ),
      serializationStatusFilter: LibrarySerializationStatusFilter.fromStorage(
        prefs.getString(_serializationStatusStorageKey),
      ),
      grouping: LibrarySeriesGrouping.fromStorage(
        prefs.getString(LibrarySeriesGrouping.storageKey),
      ),
      sortOption: decodeLibrarySeriesSortOption(
        prefs.getString(_sortStorageKey),
      ),
    );
  }

  Future<void> setAgeRestriction(LibraryAgeRestrictionFilter filter) async {
    _apply((await future).copyWith(ageRestriction: filter));
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    if (filter == LibraryAgeRestrictionFilter.unrestricted) {
      await prefs.remove(_ageStorageKey);
    } else {
      await prefs.setString(_ageStorageKey, filter.name);
    }
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
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    if (filter == LibrarySerializationStatusFilter.unrestricted) {
      await prefs.remove(_serializationStatusStorageKey);
    } else {
      await prefs.setString(_serializationStatusStorageKey, filter.name);
    }
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
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    if (grouping == LibrarySeriesGrouping.defaultValue) {
      await prefs.remove(LibrarySeriesGrouping.storageKey);
    } else {
      await prefs.setString(LibrarySeriesGrouping.storageKey, grouping.name);
    }
  }

  Future<void> setSortField(LibrarySeriesSortField field) async {
    final LibrarySeriesSortOption existing = (await future).sortOption;
    final LibrarySeriesSortOption next = existing.field == field
        ? existing.copyWith(descending: !existing.descending)
        : LibrarySeriesSortOption(field: field);
    _apply((await future).copyWith(sortOption: next));
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    if (_isDefaultSort(next)) {
      await prefs.remove(_sortStorageKey);
    } else {
      await prefs.setString(
        _sortStorageKey,
        encodeLibrarySeriesSortOption(next),
      );
    }
  }

  Future<void> resetAll() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove(_ageStorageKey);
    await prefs.remove(_serializationStatusStorageKey);
    await prefs.remove(LibrarySeriesGrouping.storageKey);
    await prefs.remove(_sortStorageKey);
    _apply(LibrarySeriesFiltersState.defaults);
  }

  void _apply(LibrarySeriesFiltersState updated) {
    state = AsyncData<LibrarySeriesFiltersState>(updated);
  }

  static bool _isDefaultSort(LibrarySeriesSortOption option) {
    return option == kLibraryDefaultSeriesSortOption;
  }
}

const SeriesCatalogQueryAssembly _seriesProjection =
    SeriesCatalogQueryAssembly();

final Provider<bool> librarySeriesFiltersIsCustomizedProvider = Provider<bool>((
  Ref ref,
) {
  final LibrarySeriesFiltersState filters =
      ref.watch(librarySeriesFiltersProvider).value ??
      LibrarySeriesFiltersState.defaults;
  return filters != LibrarySeriesFiltersState.defaults;
});

final Provider<LibrarySeriesFilter> librarySeriesFiltersQueryProvider =
    Provider<LibrarySeriesFilter>((Ref ref) {
      final LibrarySeriesFiltersState filters =
          ref.watch(librarySeriesFiltersProvider).value ??
          LibrarySeriesFiltersState.defaults;
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
          (AsyncValue<LibrarySeriesFiltersState> state) =>
              state.value?.grouping ?? LibrarySeriesGrouping.defaultValue,
        ),
      );
    });
