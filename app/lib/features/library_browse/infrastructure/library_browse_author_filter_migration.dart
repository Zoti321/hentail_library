part of 'library_browse_preferences_repository_impl.dart';

Future<LibraryMetadataFilterSelection> _loadAuthorFilter(
  SharedPreferences prefs,
  AuthorRepository authorRepository,
) async {
  final List<Author> authors = await authorRepository.listAll();
  final bool hasAuthorIdKeys =
      prefs.containsKey(_authorIncludeStorageKey) ||
      prefs.containsKey(_authorExcludeStorageKey);
  final LibraryMetadataFilterSelection authorFilter =
      migrateAuthorFilterPreference(
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
