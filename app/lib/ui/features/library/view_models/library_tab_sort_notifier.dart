import 'package:hentai_library/domain/library/library_comic_sort_option.dart';
import 'package:hentai_library/domain/models/enums.dart';
import 'package:hentai_library/ui/features/library/view_models/library_tab_filter_sort_settings.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'library_tab_sort_notifier.g.dart';

final LibraryTabSortSettings kDefaultLibraryTabSortSettings = (
  comics: LibraryComicSortOption(),
  series: LibraryComicSortOption(),
);

@Riverpod(keepAlive: true)
class LibraryTabSortNotifier extends _$LibraryTabSortNotifier {
  static const String _comicsStorageKey = 'library_sort_comics';
  static const String _seriesStorageKey = 'library_sort_series';

  @override
  Future<LibraryTabSortSettings> build() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return (
      comics: _decodeSortOption(prefs.getString(_comicsStorageKey)),
      series: _decodeSortOption(prefs.getString(_seriesStorageKey)),
    );
  }

  static LibraryComicSortOption _decodeSortOption(String? raw) {
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

  static String _encodeSortOption(LibraryComicSortOption option) {
    return '${option.field.name},${option.descending}';
  }

  static bool _isDefaultSort(LibraryComicSortOption option) {
    return option.field == kLibraryDefaultSortOption.field &&
        option.descending == kLibraryDefaultSortOption.descending;
  }

  Future<void> setSortField(
    LibraryDisplayTarget target,
    LibraryComicSortField field,
  ) async {
    final LibraryTabSortSettings current = await future;
    final LibraryComicSortOption existing = sortOptionForTarget(
      current,
      target,
    );
    final LibraryComicSortOption next = existing.field == field
        ? existing.copyWith(descending: !existing.descending)
        : LibraryComicSortOption(field: field, descending: false);
    await _updateTarget(target, next);
  }

  Future<void> _updateTarget(
    LibraryDisplayTarget target,
    LibraryComicSortOption option,
  ) async {
    final LibraryTabSortSettings current = await future;
    final LibraryTabSortSettings updated = copySortForTarget(
      current,
      target,
      option,
    );
    state = AsyncData<LibraryTabSortSettings>(updated);
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String storageKey = switch (target) {
      LibraryDisplayTarget.comics => _comicsStorageKey,
      LibraryDisplayTarget.series => _seriesStorageKey,
    };
    if (_isDefaultSort(option)) {
      await prefs.remove(storageKey);
    } else {
      await prefs.setString(storageKey, _encodeSortOption(option));
    }
  }
}
