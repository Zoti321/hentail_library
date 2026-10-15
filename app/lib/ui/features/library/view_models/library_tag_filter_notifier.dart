import 'package:hentai_library/domain/library/library_metadata_filter_selection.dart';
import 'package:hentai_library/domain/library/library_tri_state_pick.dart';
import 'package:hentai_library/ui/features/library/view_models/library_comics_catalog_controller.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'library_tag_filter_notifier.g.dart';

@Riverpod(keepAlive: true)
class LibraryTagFilterNotifier extends _$LibraryTagFilterNotifier {
  static const String _includeStorageKey = 'library_tag_filter_include';
  static const String _excludeStorageKey = 'library_tag_filter_exclude';
  static const String _includeModeStorageKey =
      'library_tag_filter_include_mode';

  @override
  Future<LibraryMetadataFilterSelection> build() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return LibraryMetadataFilterSelection.fromStorage(
      includeNames: prefs.getStringList(_includeStorageKey),
      excludeNames: prefs.getStringList(_excludeStorageKey),
      includeModeName: prefs.getString(_includeModeStorageKey),
    );
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
    ref.invalidate(libraryComicsCatalogControllerProvider);
  }
}
