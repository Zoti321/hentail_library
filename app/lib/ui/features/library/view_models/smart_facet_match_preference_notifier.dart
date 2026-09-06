import 'package:hentai_library/domain/library/smart_facet_match_preference.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'smart_facet_match_preference_notifier.g.dart';

@Riverpod(keepAlive: true)
class SmartFacetMatchPreferenceNotifier
    extends _$SmartFacetMatchPreferenceNotifier {
  static const String _storageKey = SmartFacetMatchPreference.storageKey;

  @override
  Future<bool> build() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return SmartFacetMatchPreference.fromStorage(prefs.getBool(_storageKey));
  }

  Future<void> setEnabled(bool enabled) async {
    state = AsyncData<bool>(enabled);
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    if (enabled == SmartFacetMatchPreference.defaultValue) {
      await prefs.remove(_storageKey);
    } else {
      await prefs.setBool(_storageKey, enabled);
    }
  }
}
