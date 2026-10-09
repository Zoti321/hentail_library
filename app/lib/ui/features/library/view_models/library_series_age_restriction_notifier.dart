import 'package:hentai_library/domain/library/library_age_restriction_filter.dart';
import 'package:hentai_library/ui/features/library/view_models/library_comic_filters_notifier.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'library_series_age_restriction_notifier.g.dart';

/// Series Tab 的年龄限制（Comics 侧由 [LibraryComicFiltersNotifier] 持有）。
@Riverpod(keepAlive: true)
class LibrarySeriesAgeRestrictionFilterNotifier
    extends _$LibrarySeriesAgeRestrictionFilterNotifier {
  static const String _storageKey = kLibrarySeriesAgeRestrictionStorageKey;

  @override
  Future<LibraryAgeRestrictionFilter> build() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await migrateLegacyLibraryAgeRestriction(prefs);
    return LibraryAgeRestrictionFilter.fromStorage(
      prefs.getString(_storageKey),
    );
  }

  Future<void> setFilter(LibraryAgeRestrictionFilter filter) async {
    state = AsyncData<LibraryAgeRestrictionFilter>(filter);
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    if (filter == LibraryAgeRestrictionFilter.unrestricted) {
      await prefs.remove(_storageKey);
    } else {
      await prefs.setString(_storageKey, filter.name);
    }
  }

  Future<void> toggleFilterOption(LibraryAgeRestrictionFilter option) async {
    final LibraryAgeRestrictionFilter existing = await future;
    await setFilter(
      existing == option ? LibraryAgeRestrictionFilter.unrestricted : option,
    );
  }
}
