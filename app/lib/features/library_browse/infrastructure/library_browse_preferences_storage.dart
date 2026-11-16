part of 'library_browse_preferences_repository_impl.dart';

/// 年龄限制存储键：Comics 归本模块，Series 归
/// Series browse preferences.
const String kLibraryComicsAgeRestrictionStorageKey =
    'library_age_restriction_filter_comics';
const String kLibrarySeriesAgeRestrictionStorageKey =
    'library_age_restriction_filter_series';

/// 旧版「按系列展开」布尔偏好一次性迁移为分组方式（新键缺失时才迁移）。
///
/// 旧键为 `false` 迁移为 [LibraryComicGrouping.none]，否则为 [LibraryComicGrouping.bySeries]；
/// 迁移后删除旧键，重复执行结果一致。
Future<void> migrateLegacyLibraryComicGrouping(SharedPreferences prefs) async {
  const String legacyKey = LibraryComicGrouping.legacyExpandBySeriesStorageKey;
  if (!prefs.containsKey(legacyKey)) {
    return;
  }
  if (!prefs.containsKey(LibraryComicGrouping.storageKey)) {
    final bool expandBySeries = prefs.getBool(legacyKey) ?? true;
    final LibraryComicGrouping migrated = expandBySeries
        ? LibraryComicGrouping.bySeries
        : LibraryComicGrouping.none;
    if (migrated != LibraryComicGrouping.defaultValue) {
      await prefs.setString(LibraryComicGrouping.storageKey, migrated.name);
    }
  }
  await prefs.remove(legacyKey);
}

/// 旧版单键年龄限制一次性迁移到 Comics / Series 双键。
Future<void> migrateLegacyLibraryAgeRestriction(SharedPreferences prefs) async {
  if (!prefs.containsKey(kLibraryComicsAgeRestrictionStorageKey) &&
      !prefs.containsKey(kLibrarySeriesAgeRestrictionStorageKey) &&
      prefs.containsKey(kLegacyLibraryAgeRestrictionStorageKey)) {
    final LibraryAgeRestrictionFilter legacy =
        LibraryAgeRestrictionFilter.fromStorage(
          prefs.getString(kLegacyLibraryAgeRestrictionStorageKey),
        );
    if (legacy != LibraryAgeRestrictionFilter.unrestricted) {
      await prefs.setString(
        kLibraryComicsAgeRestrictionStorageKey,
        legacy.name,
      );
      await prefs.setString(
        kLibrarySeriesAgeRestrictionStorageKey,
        legacy.name,
      );
    }
    await prefs.remove(kLegacyLibraryAgeRestrictionStorageKey);
  }
}

/// Comics Tab 筛选偏好的 SharedPreferences 键（#308 持久化侧，供主类与 mixin 共用）。
const String _ageStorageKey = kLibraryComicsAgeRestrictionStorageKey;
const String _mediaTypeStorageKey = 'library_media_type_filter_comics';
const String _tagIncludeStorageKey = 'library_tag_filter_include';
const String _tagExcludeStorageKey = 'library_tag_filter_exclude';
const String _tagIncludeModeStorageKey = 'library_tag_filter_include_mode';
const String _authorIncludeStorageKey = 'library_author_filter_include_ids';
const String _authorExcludeStorageKey = 'library_author_filter_exclude_ids';
const String _authorIncludeModeStorageKey =
    'library_author_filter_include_mode';
const String _legacyAuthorIncludeStorageKey = 'library_author_filter_include';
const String _legacyAuthorExcludeStorageKey = 'library_author_filter_exclude';
const String _sortStorageKey = 'library_sort_comics';

/// 旧版单键年龄限制偏好（#308 迁移源）；已废弃，仅一次性迁移读取。
const String kLegacyLibraryAgeRestrictionStorageKey =
    'library_age_restriction_filter';

/// 元数据（标签 / 作者）筛选在 SharedPreferences 中的三个键，成组使用。
class _MetadataStorageKeys {
  const _MetadataStorageKeys({
    required this.include,
    required this.exclude,
    required this.includeMode,
  });

  final String include;
  final String exclude;
  final String includeMode;
}

const _MetadataStorageKeys _tagStorageKeys = _MetadataStorageKeys(
  include: _tagIncludeStorageKey,
  exclude: _tagExcludeStorageKey,
  includeMode: _tagIncludeModeStorageKey,
);

const _MetadataStorageKeys _authorStorageKeys = _MetadataStorageKeys(
  include: _authorIncludeStorageKey,
  exclude: _authorExcludeStorageKey,
  includeMode: _authorIncludeModeStorageKey,
);

/// 写回元数据（标签 / 作者）筛选选择到 SharedPreferences（#308 持久化侧）。
Future<void> _writeMetadataSelection(
  SharedPreferences prefs,
  LibraryMetadataFilterSelection selection, {
  required _MetadataStorageKeys keys,
}) async {
  if (!selection.isActive &&
      selection.includeMode == LibraryMetadataIncludeMode.any) {
    await prefs.remove(keys.include);
    await prefs.remove(keys.exclude);
    await prefs.remove(keys.includeMode);
    return;
  }
  if (selection.includeNames().isEmpty) {
    await prefs.remove(keys.include);
  } else {
    await prefs.setStringList(keys.include, selection.includeNamesToStorage());
  }
  if (selection.excludeNames().isEmpty) {
    await prefs.remove(keys.exclude);
  } else {
    await prefs.setStringList(keys.exclude, selection.excludeNamesToStorage());
  }
  if (selection.includeMode == LibraryMetadataIncludeMode.any) {
    await prefs.remove(keys.includeMode);
  } else {
    await prefs.setString(keys.includeMode, selection.includeMode.name);
  }
}

/// 排序偏好的默认值判断与持久化编解码（#308 持久化侧）。
bool _isDefaultComicSort(LibraryComicSortOption option) {
  return option.field == kLibraryDefaultSortOption.field &&
      option.descending == kLibraryDefaultSortOption.descending;
}

String _encodeComicSortOption(LibraryComicSortOption option) {
  return '${option.field.name},${option.descending}';
}

LibraryComicSortOption _decodeComicSortOption(String? raw) {
  if (raw == null || raw.isEmpty) {
    return kLibraryDefaultSortOption;
  }
  final List<String> parts = raw.split(',');
  if (parts.length != 2) {
    return kLibraryDefaultSortOption;
  }
  final LibraryComicSortField? field = LibraryComicSortField.values
      .asNameMap()[parts.first];
  if (field == null) {
    return kLibraryDefaultSortOption;
  }
  return LibraryComicSortOption(field: field, descending: parts[1] == 'true');
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
  final String fieldName = parts.first == 'title' ? 'name' : parts.first;
  final LibrarySeriesSortField? field = LibrarySeriesSortField.values
      .asNameMap()[fieldName];
  if (field == null) {
    return kLibraryDefaultSeriesSortOption;
  }
  return LibrarySeriesSortOption(field: field, descending: parts[1] == 'true');
}
