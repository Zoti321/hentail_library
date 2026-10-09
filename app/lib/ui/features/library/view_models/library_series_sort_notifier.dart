import 'package:hentai_library/domain/library/library_series_sort_option.dart';
import 'package:hentai_library/ui/features/library/view_models/library_series_sort_codec.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'library_series_sort_notifier.g.dart';

/// Series Tab 排序（Comics 侧由 [LibraryComicFiltersNotifier] 持有）。
@Riverpod(keepAlive: true)
class LibrarySeriesSortNotifier extends _$LibrarySeriesSortNotifier {
  static const String _storageKey = 'library_sort_series';

  @override
  Future<LibrarySeriesSortOption> build() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return decodeLibrarySeriesSortOption(prefs.getString(_storageKey));
  }

  Future<void> setSortField(LibrarySeriesSortField field) async {
    final LibrarySeriesSortOption existing = await future;
    final LibrarySeriesSortOption next = existing.field == field
        ? existing.copyWith(descending: !existing.descending)
        : LibrarySeriesSortOption(field: field, descending: false);
    await _update(next);
  }

  Future<void> resetSeriesSortToDefault() async {
    await _update(kLibraryDefaultSeriesSortOption);
  }

  Future<void> _update(LibrarySeriesSortOption option) async {
    state = AsyncData<LibrarySeriesSortOption>(option);
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    if (isDefaultLibrarySeriesSort(option)) {
      await prefs.remove(_storageKey);
    } else {
      await prefs.setString(_storageKey, encodeLibrarySeriesSortOption(option));
    }
  }
}
