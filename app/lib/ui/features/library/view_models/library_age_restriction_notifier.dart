import 'package:hentai_library/domain/library/library_age_restriction_filter.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'library_age_restriction_notifier.g.dart';

@Riverpod(keepAlive: true)
class LibraryAgeRestrictionFilterNotifier
    extends _$LibraryAgeRestrictionFilterNotifier {
  @override
  Future<LibraryAgeRestrictionFilter> build() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return LibraryAgeRestrictionFilter.fromStorage(
      prefs.getString(LibraryAgeRestrictionFilter.storageKey),
    );
  }

  Future<void> setFilter(LibraryAgeRestrictionFilter filter) async {
    state = AsyncData<LibraryAgeRestrictionFilter>(filter);
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(LibraryAgeRestrictionFilter.storageKey, filter.name);
  }
}
