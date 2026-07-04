import 'package:hentai_library/domain/library/library_age_restriction_filter.dart';
import 'package:hentai_library/domain/models/enums.dart';
import 'package:hentai_library/ui/features/library/view_models/library_tab_filter_sort_settings.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'library_age_restriction_notifier.g.dart';

const LibraryTabAgeRestrictionSettings
kDefaultLibraryTabAgeRestrictionSettings = (
  comics: LibraryAgeRestrictionFilter.unrestricted,
  series: LibraryAgeRestrictionFilter.unrestricted,
);

@Riverpod(keepAlive: true)
class LibraryAgeRestrictionFilterNotifier
    extends _$LibraryAgeRestrictionFilterNotifier {
  static const String _legacyStorageKey =
      LibraryAgeRestrictionFilter.storageKey;
  static const String _comicsStorageKey =
      'library_age_restriction_filter_comics';
  static const String _seriesStorageKey =
      'library_age_restriction_filter_series';

  @override
  Future<LibraryTabAgeRestrictionSettings> build() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await _migrateLegacy(prefs);
    return (
      comics: LibraryAgeRestrictionFilter.fromStorage(
        prefs.getString(_comicsStorageKey),
      ),
      series: LibraryAgeRestrictionFilter.fromStorage(
        prefs.getString(_seriesStorageKey),
      ),
    );
  }

  Future<void> _migrateLegacy(SharedPreferences prefs) async {
    if (!prefs.containsKey(_comicsStorageKey) &&
        !prefs.containsKey(_seriesStorageKey) &&
        prefs.containsKey(_legacyStorageKey)) {
      final LibraryAgeRestrictionFilter legacy =
          LibraryAgeRestrictionFilter.fromStorage(
            prefs.getString(_legacyStorageKey),
          );
      if (legacy != LibraryAgeRestrictionFilter.unrestricted) {
        await prefs.setString(_comicsStorageKey, legacy.name);
        await prefs.setString(_seriesStorageKey, legacy.name);
      }
      await prefs.remove(_legacyStorageKey);
    }
  }

  Future<void> setFilter(
    LibraryDisplayTarget target,
    LibraryAgeRestrictionFilter filter,
  ) async {
    final LibraryTabAgeRestrictionSettings current = await future;
    final LibraryTabAgeRestrictionSettings updated =
        copyAgeRestrictionForTarget(current, target, filter);
    state = AsyncData<LibraryTabAgeRestrictionSettings>(updated);
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String storageKey = switch (target) {
      LibraryDisplayTarget.comics => _comicsStorageKey,
      LibraryDisplayTarget.series => _seriesStorageKey,
    };
    if (filter == LibraryAgeRestrictionFilter.unrestricted) {
      await prefs.remove(storageKey);
    } else {
      await prefs.setString(storageKey, filter.name);
    }
  }

  Future<void> toggleFilterOption(
    LibraryDisplayTarget target,
    LibraryAgeRestrictionFilter option,
  ) async {
    final LibraryTabAgeRestrictionSettings current = await future;
    final LibraryAgeRestrictionFilter existing = ageRestrictionForTarget(
      current,
      target,
    );
    if (existing == option) {
      await setFilter(target, LibraryAgeRestrictionFilter.unrestricted);
      return;
    }
    await setFilter(target, option);
  }
}
