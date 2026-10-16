import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/domain/library/library_age_restriction_filter.dart';
import 'package:hentai_library/features/library_browse/domain/library_prefer_library_root_series.dart';
import 'package:hentai_library/features/library_browse/domain/library_series_projection.dart';
import 'package:hentai_library/domain/library/library_series_sort_option.dart';
import 'package:hentai_library/domain/library/library_serialization_status_filter.dart';
import 'package:hentai_library/features/library_browse/presentation/view_models/library_comic_filters_notifier.dart';
import 'package:hentai_library/features/library_browse/presentation/view_models/library_query_intent.dart';
import 'package:hentai_library/features/library_browse/presentation/view_models/library_query_intent_notifier.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'library_series_filters_notifier.g.dart';

/// Series Tab 的 Library browse preference：单一不可变值对象，四个维度全部落盘。
///
/// 与 Comics 侧 [LibraryComicFiltersState] 同形；新增一个 Series 维度只需改动
/// 此处（字段 + 默认值 + copyWith/==/hashCode）与 [LibrarySeriesFiltersNotifier]。
class LibrarySeriesFiltersState {
  const LibrarySeriesFiltersState({
    this.ageRestriction = LibraryAgeRestrictionFilter.unrestricted,
    this.serializationStatusFilter =
        LibrarySerializationStatusFilter.unrestricted,
    this.preferLibraryRootSeries = LibraryPreferLibraryRootSeries.defaultValue,
    this.sortOption = kLibraryDefaultSeriesSortOption,
  });

  /// 默认（未筛选）状态；加载完成前的占位值。
  static const LibrarySeriesFiltersState defaults = LibrarySeriesFiltersState();

  final LibraryAgeRestrictionFilter ageRestriction;
  final LibrarySerializationStatusFilter serializationStatusFilter;
  final bool preferLibraryRootSeries;
  final LibrarySeriesSortOption sortOption;

  LibrarySeriesFiltersState copyWith({
    LibraryAgeRestrictionFilter? ageRestriction,
    LibrarySerializationStatusFilter? serializationStatusFilter,
    bool? preferLibraryRootSeries,
    LibrarySeriesSortOption? sortOption,
  }) {
    return LibrarySeriesFiltersState(
      ageRestriction: ageRestriction ?? this.ageRestriction,
      serializationStatusFilter:
          serializationStatusFilter ?? this.serializationStatusFilter,
      preferLibraryRootSeries:
          preferLibraryRootSeries ?? this.preferLibraryRootSeries,
      sortOption: sortOption ?? this.sortOption,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is LibrarySeriesFiltersState &&
            other.ageRestriction == ageRestriction &&
            other.serializationStatusFilter == serializationStatusFilter &&
            other.preferLibraryRootSeries == preferLibraryRootSeries &&
            other.sortOption == sortOption;
  }

  @override
  int get hashCode => Object.hash(
    ageRestriction,
    serializationStatusFilter,
    preferLibraryRootSeries,
    sortOption,
  );
}

/// Series Tab 排序偏好的落盘编码。
///
/// 旧版键值里的 `title` 字段名映射到 [LibrarySeriesSortField.name]；非法值回落默认。
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

/// Series Tab 的 Library browse preference（筛选 + 排序）唯一事实来源。
///
/// 持有四个落盘维度；命令方法负责写回 SharedPreferences，
/// [resetAll] 清空本模块全部键并恢复默认。派生 [librarySeriesFiltersQueryProvider]
/// 供 Series 目录查询消费。
@Riverpod(keepAlive: true)
class LibrarySeriesFiltersNotifier extends _$LibrarySeriesFiltersNotifier {
  static const String _ageStorageKey = kLibrarySeriesAgeRestrictionStorageKey;
  static const String _serializationStatusStorageKey =
      LibrarySerializationStatusFilter.storageKey;
  static const String _preferLibraryRootSeriesStorageKey =
      LibraryPreferLibraryRootSeries.storageKey;
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
      preferLibraryRootSeries: LibraryPreferLibraryRootSeries.fromStorage(
        prefs.getBool(_preferLibraryRootSeriesStorageKey),
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

  Future<void> setPreferLibraryRootSeries(bool enabled) async {
    _apply((await future).copyWith(preferLibraryRootSeries: enabled));
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    if (enabled == LibraryPreferLibraryRootSeries.defaultValue) {
      await prefs.remove(_preferLibraryRootSeriesStorageKey);
    } else {
      await prefs.setBool(_preferLibraryRootSeriesStorageKey, enabled);
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

  /// 清空 Series Tab 的全部筛选与排序，恢复默认。
  Future<void> resetAll() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove(_ageStorageKey);
    await prefs.remove(_serializationStatusStorageKey);
    await prefs.remove(_preferLibraryRootSeriesStorageKey);
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

const LibrarySeriesProjection _seriesProjection = LibrarySeriesProjection();

/// Series Tab 是否含有非默认筛选 / 排序。
final Provider<bool> librarySeriesFiltersIsCustomizedProvider = Provider<bool>((
  Ref ref,
) {
  final LibrarySeriesFiltersState filters =
      ref.watch(librarySeriesFiltersProvider).value ??
      LibrarySeriesFiltersState.defaults;
  // 逐维度手写比较会漏掉以后新增的维度；值对象自带 ==，与默认值不同即视为已自定义。
  return filters != LibrarySeriesFiltersState.defaults;
});

/// Series Tab 筛选意图派生出的 Rust 查询 filter（含关键词）。
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
      return _seriesProjection.buildListFilter(
        ageRestriction: filters.ageRestriction,
        serializationStatusFilter: filters.serializationStatusFilter,
        preferLibraryRootSeries: filters.preferLibraryRootSeries,
        keyword: keyword,
      );
    });
