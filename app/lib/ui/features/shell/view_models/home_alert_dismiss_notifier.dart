import 'dart:convert';

import 'package:hentai_library/domain/models/read_models/home_page_read_models.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'home_alert_dismiss_notifier.g.dart';

const String _kHomeAlertDismissedKey = 'home_alert_dismissed';

@Riverpod(keepAlive: true)
class HomeAlertDismissRevision extends _$HomeAlertDismissRevision {
  @override
  int build() => 0;

  void bump() => state++;
}

@Riverpod(keepAlive: true)
class HomeAlertDismissStore extends _$HomeAlertDismissStore {
  @override
  Future<Map<String, int>> build() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return _readMap(prefs);
  }

  Future<void> dismiss(HomeLibraryAlert alert) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final Map<String, int> map = _readMap(prefs);
    map[alert.dismissKey()] = DateTime.now().millisecondsSinceEpoch;
    await prefs.setString(_kHomeAlertDismissedKey, jsonEncode(map));
    ref.invalidateSelf();
    ref.read(homeAlertDismissRevisionProvider.notifier).bump();
  }

  Future<void> clearForLibrary(String libraryId) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final Map<String, int> map = _readMap(prefs);
    map.removeWhere((String key, _) => key.startsWith('$libraryId:'));
    await prefs.setString(_kHomeAlertDismissedKey, jsonEncode(map));
    ref.invalidateSelf();
    ref.read(homeAlertDismissRevisionProvider.notifier).bump();
  }

  Future<void> clearForLibraryKind(String libraryId, HomeLibraryAlertKind kind) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final Map<String, int> map = _readMap(prefs);
    map.remove('$libraryId:${kind.name}');
    await prefs.setString(_kHomeAlertDismissedKey, jsonEncode(map));
    ref.invalidateSelf();
    ref.read(homeAlertDismissRevisionProvider.notifier).bump();
  }

  Map<String, int> _readMap(SharedPreferences prefs) {
    final String? raw = prefs.getString(_kHomeAlertDismissedKey);
    if (raw == null || raw.isEmpty) {
      return <String, int>{};
    }
    try {
      final Object? decoded = jsonDecode(raw);
      if (decoded is! Map) {
        return <String, int>{};
      }
      return Map<String, int>.fromEntries(
        decoded.entries.map(
          (MapEntry<dynamic, dynamic> entry) => MapEntry<String, int>(
            entry.key.toString(),
            entry.value is int
                ? entry.value as int
                : int.tryParse('${entry.value}') ?? 0,
          ),
        ),
      );
    } catch (_) {
      return <String, int>{};
    }
  }
}

List<HomeLibraryAlert> filterDismissedHomeAlerts({
  required List<HomeLibraryAlert> alerts,
  required Map<String, int> dismissed,
}) {
  if (dismissed.isEmpty) {
    return alerts;
  }
  return alerts
      .where((HomeLibraryAlert alert) => !dismissed.containsKey(alert.dismissKey()))
      .toList(growable: false);
}
