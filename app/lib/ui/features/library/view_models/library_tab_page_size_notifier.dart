import 'package:hentai_library/domain/models/enums.dart';
import 'package:hentai_library/domain/models/value_objects/page_request.dart';
import 'package:hentai_library/ui/features/library/view_models/library_tab_page_size_settings.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'library_tab_page_size_notifier.g.dart';

@Riverpod(keepAlive: true)
class LibraryTabPageSizeNotifier extends _$LibraryTabPageSizeNotifier {
  static const String _comicsStorageKey = 'library_page_size_comics';
  static const String _seriesStorageKey = 'library_page_size_series';

  @override
  Future<LibraryTabPageSizeSettings> build() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return (
      comics: normalizeLibraryPageSize(prefs.getInt(_comicsStorageKey)),
      series: normalizeLibraryPageSize(prefs.getInt(_seriesStorageKey)),
    );
  }

  Future<void> setPageSize(LibraryDisplayTarget target, int pageSize) async {
    final int normalized = normalizeLibraryPageSize(pageSize);
    final LibraryTabPageSizeSettings current = await future;
    final LibraryTabPageSizeSettings updated = copyPageSizeForTarget(
      current,
      target,
      normalized,
    );
    state = AsyncData<LibraryTabPageSizeSettings>(updated);
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String storageKey = switch (target) {
      LibraryDisplayTarget.comics => _comicsStorageKey,
      LibraryDisplayTarget.series => _seriesStorageKey,
    };
    if (normalized == kDefaultPageSize) {
      await prefs.remove(storageKey);
    } else {
      await prefs.setInt(storageKey, normalized);
    }
  }
}
