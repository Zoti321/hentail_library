import 'package:hentai_library/domain/library/library_prefer_library_root_series.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'library_prefer_library_root_series_notifier.g.dart';

@Riverpod(keepAlive: true)
class LibraryPreferLibraryRootSeriesNotifier
    extends _$LibraryPreferLibraryRootSeriesNotifier {
  static const String _storageKey = LibraryPreferLibraryRootSeries.storageKey;

  @override
  Future<bool> build() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return LibraryPreferLibraryRootSeries.fromStorage(
      prefs.getBool(_storageKey),
    );
  }

  Future<void> setEnabled(bool enabled) async {
    state = AsyncData<bool>(enabled);
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    if (enabled == LibraryPreferLibraryRootSeries.defaultValue) {
      await prefs.remove(_storageKey);
    } else {
      await prefs.setBool(_storageKey, enabled);
    }
  }
}
