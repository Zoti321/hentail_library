import 'package:hentai_library/domain/library/library_media_type_filter.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'library_media_type_filter_notifier.g.dart';

@Riverpod(keepAlive: true)
class LibraryMediaTypeFilterNotifier extends _$LibraryMediaTypeFilterNotifier {
  static const String _storageKey = 'library_media_type_filter_comics';

  @override
  Future<LibraryMediaTypeFilterSelection> build() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return LibraryMediaTypeFilterSelection.fromStorage(
      prefs.getStringList(_storageKey),
    );
  }

  Future<void> toggleOption(LibraryMediaTypeFilterOption option) async {
    final LibraryMediaTypeFilterSelection current = await future;
    final LibraryMediaTypeFilterSelection updated = current.withToggled(option);
    state = AsyncData<LibraryMediaTypeFilterSelection>(updated);
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    if (updated.selected.isEmpty) {
      await prefs.remove(_storageKey);
    } else {
      await prefs.setStringList(_storageKey, updated.toStorage());
    }
  }
}
