import 'package:hentai_library/domain/library/library_needs_metadata_only.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'library_needs_metadata_only_notifier.g.dart';

@Riverpod(keepAlive: true)
class LibraryNeedsMetadataOnlyNotifier
    extends _$LibraryNeedsMetadataOnlyNotifier {
  static const String _storageKey = LibraryNeedsMetadataOnly.storageKey;

  @override
  Future<bool> build() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return LibraryNeedsMetadataOnly.fromStorage(prefs.getBool(_storageKey));
  }

  Future<void> setEnabled(bool enabled) async {
    state = AsyncData<bool>(enabled);
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    if (enabled == LibraryNeedsMetadataOnly.defaultValue) {
      await prefs.remove(_storageKey);
    } else {
      await prefs.setBool(_storageKey, enabled);
    }
  }
}
