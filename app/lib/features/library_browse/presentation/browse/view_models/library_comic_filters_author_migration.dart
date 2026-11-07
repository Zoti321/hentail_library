part of 'library_comic_filters_notifier.dart';

/// 读取作者目录并迁移旧版作者筛选偏好（名称 → id 键），并写回 SharedPreferences（#308）。
mixin _LibraryComicFiltersAuthorMigration on _$LibraryComicFiltersNotifier {
  Future<LibraryMetadataFilterSelection> _loadAuthorFilter(
    SharedPreferences prefs,
  ) async {
    final List<Author> authors = await ref.read(authorRepoProvider).listAll();
    final bool hasAuthorIdKeys =
        prefs.containsKey(_authorIncludeStorageKey) ||
        prefs.containsKey(_authorExcludeStorageKey);
    final LibraryMetadataFilterSelection
    authorFilter = migrateAuthorFilterPreference(
      includeIds: hasAuthorIdKeys
          ? prefs.getStringList(_authorIncludeStorageKey)
          : null,
      excludeIds: hasAuthorIdKeys
          ? prefs.getStringList(_authorExcludeStorageKey)
          : null,
      legacyIncludeNames: prefs.getStringList(_legacyAuthorIncludeStorageKey),
      legacyExcludeNames: prefs.getStringList(_legacyAuthorExcludeStorageKey),
      includeModeName: prefs.getString(_authorIncludeModeStorageKey),
      authors: authors,
    );
    if (!hasAuthorIdKeys &&
        (prefs.containsKey(_legacyAuthorIncludeStorageKey) ||
            prefs.containsKey(_legacyAuthorExcludeStorageKey))) {
      await _writeMetadataSelection(
        prefs,
        authorFilter,
        keys: _authorStorageKeys,
      );
      await prefs.remove(_legacyAuthorIncludeStorageKey);
      await prefs.remove(_legacyAuthorExcludeStorageKey);
    }
    return authorFilter;
  }
}
