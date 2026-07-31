import 'package:hentai_library/domain/library/library_serialization_status_filter.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'library_serialization_status_filter_notifier.g.dart';

@Riverpod(keepAlive: true)
class LibrarySerializationStatusFilterNotifier
    extends _$LibrarySerializationStatusFilterNotifier {
  static const String _storageKey = LibrarySerializationStatusFilter.storageKey;

  @override
  Future<LibrarySerializationStatusFilter> build() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return LibrarySerializationStatusFilter.fromStorage(
      prefs.getString(_storageKey),
    );
  }

  Future<void> setFilter(LibrarySerializationStatusFilter filter) async {
    state = AsyncData<LibrarySerializationStatusFilter>(filter);
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    if (filter == LibrarySerializationStatusFilter.unrestricted) {
      await prefs.remove(_storageKey);
    } else {
      await prefs.setString(_storageKey, filter.name);
    }
  }

  Future<void> toggleFilterOption(
    LibrarySerializationStatusFilter option,
  ) async {
    final LibrarySerializationStatusFilter existing = await future;
    if (existing == option) {
      await setFilter(LibrarySerializationStatusFilter.unrestricted);
      return;
    }
    await setFilter(option);
  }
}
