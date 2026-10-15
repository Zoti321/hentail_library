import 'package:hentai_library/domain/library/library_expand_by_series.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'library_expand_by_series_notifier.g.dart';

@Riverpod(keepAlive: true)
class LibraryExpandBySeriesNotifier extends _$LibraryExpandBySeriesNotifier {
  static const String _storageKey = LibraryExpandBySeries.storageKey;

  @override
  Future<bool> build() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return LibraryExpandBySeries.fromStorage(prefs.getBool(_storageKey));
  }

  Future<void> setEnabled(bool enabled) async {
    state = AsyncData<bool>(enabled);
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    if (enabled == LibraryExpandBySeries.defaultValue) {
      await prefs.remove(_storageKey);
    } else {
      await prefs.setBool(_storageKey, enabled);
    }
  }
}
