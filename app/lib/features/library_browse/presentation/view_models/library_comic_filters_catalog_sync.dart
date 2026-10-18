part of 'library_comic_filters_notifier.dart';

/// 与 Author 目录同步：读取作者目录并迁移旧版作者筛选偏好（#308 catalog 同步侧）。
mixin _LibraryComicFiltersCatalogSync on _$LibraryComicFiltersNotifier {
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
        includeKey: _authorIncludeStorageKey,
        excludeKey: _authorExcludeStorageKey,
        includeModeKey: _authorIncludeModeStorageKey,
      );
      await prefs.remove(_legacyAuthorIncludeStorageKey);
      await prefs.remove(_legacyAuthorExcludeStorageKey);
    }
    return authorFilter;
  }
}
