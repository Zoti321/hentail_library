part of 'library_comic_filters_notifier.dart';

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
      .asNameMap()[parts[0]];
  if (field == null) {
    return kLibraryDefaultSortOption;
  }
  return LibraryComicSortOption(field: field, descending: parts[1] == 'true');
}
