import 'package:hentai_library/domain/library/author_filter_preference_migration.dart';
import 'package:hentai_library/domain/library/library_metadata_filter_selection.dart';
import 'package:hentai_library/domain/library/library_tri_state_pick.dart';
import 'package:hentai_library/ui/features/shell/di/deps.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'library_author_filter_notifier.g.dart';

@Riverpod(keepAlive: true)
class LibraryAuthorFilterNotifier extends _$LibraryAuthorFilterNotifier {
  static const String _includeStorageKey = 'library_author_filter_include_ids';
  static const String _excludeStorageKey = 'library_author_filter_exclude_ids';
  static const String _includeModeStorageKey =
      'library_author_filter_include_mode';
  static const String _legacyIncludeStorageKey =
      'library_author_filter_include';
  static const String _legacyExcludeStorageKey =
      'library_author_filter_exclude';

  @override
  Future<LibraryMetadataFilterSelection> build() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final authors = await ref.read(authorRepoProvider).listAll();
    final bool hasNewKeys =
        prefs.containsKey(_includeStorageKey) ||
        prefs.containsKey(_excludeStorageKey);
    final LibraryMetadataFilterSelection
    selection = migrateAuthorFilterPreference(
      includeIds: hasNewKeys ? prefs.getStringList(_includeStorageKey) : null,
      excludeIds: hasNewKeys ? prefs.getStringList(_excludeStorageKey) : null,
      legacyIncludeNames: prefs.getStringList(_legacyIncludeStorageKey),
      legacyExcludeNames: prefs.getStringList(_legacyExcludeStorageKey),
      includeModeName: prefs.getString(_includeModeStorageKey),
      authors: authors,
    );
    if (!hasNewKeys &&
        (prefs.containsKey(_legacyIncludeStorageKey) ||
            prefs.containsKey(_legacyExcludeStorageKey))) {
      await _write(prefs, selection);
      await prefs.remove(_legacyIncludeStorageKey);
      await prefs.remove(_legacyExcludeStorageKey);
    }
    return selection;
  }

  Future<void> toggle(String name) async {
    final LibraryMetadataFilterSelection current = await future;
    await _persist(current.withToggled(name));
  }

  Future<void> setIncludeMode(LibraryMetadataIncludeMode mode) async {
    final LibraryMetadataFilterSelection current = await future;
    await _persist(current.withIncludeMode(mode));
  }

  Future<void> clear() async {
    final LibraryMetadataFilterSelection current = await future;
    await _persist(current.cleared());
  }

  Future<void> _persist(LibraryMetadataFilterSelection updated) async {
    state = AsyncData<LibraryMetadataFilterSelection>(updated);
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await _write(prefs, updated);
  }

  Future<void> _write(
    SharedPreferences prefs,
    LibraryMetadataFilterSelection updated,
  ) async {
    if (!updated.isActive &&
        updated.includeMode == LibraryMetadataIncludeMode.any) {
      await prefs.remove(_includeStorageKey);
      await prefs.remove(_excludeStorageKey);
      await prefs.remove(_includeModeStorageKey);
      return;
    }
    if (updated.includeNames().isEmpty) {
      await prefs.remove(_includeStorageKey);
    } else {
      await prefs.setStringList(
        _includeStorageKey,
        updated.includeNamesToStorage(),
      );
    }
    if (updated.excludeNames().isEmpty) {
      await prefs.remove(_excludeStorageKey);
    } else {
      await prefs.setStringList(
        _excludeStorageKey,
        updated.excludeNamesToStorage(),
      );
    }
    if (updated.includeMode == LibraryMetadataIncludeMode.any) {
      await prefs.remove(_includeModeStorageKey);
    } else {
      await prefs.setString(_includeModeStorageKey, updated.includeMode.name);
    }
  }
}
