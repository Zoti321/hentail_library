import 'package:hentai_library/domain/library/library_comic_sort_option.dart';
import 'package:hentai_library/domain/library/library_series_sort_option.dart';
import 'package:hentai_library/ui/features/library/view_models/library_comics_catalog_controller.dart';
import 'package:hentai_library/ui/features/library/view_models/library_series_catalog_controller.dart';
import 'package:hentai_library/ui/features/library/view_models/library_series_sort_codec.dart';
import 'package:hentai_library/ui/features/library/view_models/library_tab_filter_sort_settings.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'library_tab_sort_notifier.g.dart';

final LibraryTabSortSettings kDefaultLibraryTabSortSettings = (
  comics: LibraryComicSortOption(),
  series: LibrarySeriesSortOption(),
);

@Riverpod(keepAlive: true)
class LibraryTabSortNotifier extends _$LibraryTabSortNotifier {
  static const String _comicsStorageKey = 'library_sort_comics';
  static const String _seriesStorageKey = 'library_sort_series';

  @override
  Future<LibraryTabSortSettings> build() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return (
      comics: _decodeComicSortOption(prefs.getString(_comicsStorageKey)),
      series: decodeLibrarySeriesSortOption(prefs.getString(_seriesStorageKey)),
    );
  }

  static LibraryComicSortOption _decodeComicSortOption(String? raw) {
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

  static String _encodeComicSortOption(LibraryComicSortOption option) {
    return '${option.field.name},${option.descending}';
  }

  static bool _isDefaultComicSort(LibraryComicSortOption option) {
    return option.field == kLibraryDefaultSortOption.field &&
        option.descending == kLibraryDefaultSortOption.descending;
  }

  Future<void> setComicSortField(LibraryComicSortField field) async {
    final LibraryTabSortSettings current = await future;
    final LibraryComicSortOption existing = current.comics;
    final LibraryComicSortOption next = existing.field == field
        ? existing.copyWith(descending: !existing.descending)
        : LibraryComicSortOption(field: field, descending: false);
    await _updateComicSort(next);
  }

  Future<void> setSeriesSortField(LibrarySeriesSortField field) async {
    final LibraryTabSortSettings current = await future;
    final LibrarySeriesSortOption existing = current.series;
    final LibrarySeriesSortOption next = existing.field == field
        ? existing.copyWith(descending: !existing.descending)
        : LibrarySeriesSortOption(field: field, descending: false);
    await _updateSeriesSort(next);
  }

  Future<void> _updateComicSort(LibraryComicSortOption option) async {
    final LibraryTabSortSettings current = await future;
    final LibraryTabSortSettings updated = copyComicSortForTarget(
      current,
      option,
    );
    state = AsyncData<LibraryTabSortSettings>(updated);
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    if (_isDefaultComicSort(option)) {
      await prefs.remove(_comicsStorageKey);
    } else {
      await prefs.setString(_comicsStorageKey, _encodeComicSortOption(option));
    }
    ref.invalidate(libraryComicsCatalogControllerProvider);
  }

  Future<void> _updateSeriesSort(LibrarySeriesSortOption option) async {
    final LibraryTabSortSettings current = await future;
    final LibraryTabSortSettings updated = copySeriesSortForTarget(
      current,
      option,
    );
    state = AsyncData<LibraryTabSortSettings>(updated);
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    if (isDefaultLibrarySeriesSort(option)) {
      await prefs.remove(_seriesStorageKey);
    } else {
      await prefs.setString(
        _seriesStorageKey,
        encodeLibrarySeriesSortOption(option),
      );
    }
    ref.invalidate(librarySeriesCatalogControllerProvider);
  }
}
