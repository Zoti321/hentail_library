part of 'library_comic_filters_notifier.dart';

/// 写回元数据（标签 / 作者）筛选选择到 SharedPreferences（#308 持久化侧）。
Future<void> _writeMetadataSelection(
  SharedPreferences prefs,
  LibraryMetadataFilterSelection selection, {
  required String includeKey,
  required String excludeKey,
  required String includeModeKey,
}) async {
  if (!selection.isActive &&
      selection.includeMode == LibraryMetadataIncludeMode.any) {
    await prefs.remove(includeKey);
    await prefs.remove(excludeKey);
    await prefs.remove(includeModeKey);
    return;
  }
  if (selection.includeNames().isEmpty) {
    await prefs.remove(includeKey);
  } else {
    await prefs.setStringList(includeKey, selection.includeNamesToStorage());
  }
  if (selection.excludeNames().isEmpty) {
    await prefs.remove(excludeKey);
  } else {
    await prefs.setStringList(excludeKey, selection.excludeNamesToStorage());
  }
  if (selection.includeMode == LibraryMetadataIncludeMode.any) {
    await prefs.remove(includeModeKey);
  } else {
    await prefs.setString(includeModeKey, selection.includeMode.name);
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
