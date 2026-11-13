import 'dart:convert';

import 'package:hentai_library/features/home/domain/home_alert_dismissal.dart';
import 'package:hentai_library/features/home/domain/home_alert_dismiss_repository.dart';
import 'package:hentai_library/features/home/domain/home_page_read_models.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String _kHomeAlertDismissedKey = 'home_alert_dismissed';

class HomeAlertDismissRepositoryImpl implements HomeAlertDismissRepository {
  const HomeAlertDismissRepositoryImpl();

  @override
  Future<Map<String, HomeAlertDismissEntry>> load() async {
    return _readMap(await SharedPreferences.getInstance());
  }

  @override
  Future<void> dismiss(HomeLibraryAlert alert, DateTime dismissedAt) async {
    final prefs = await SharedPreferences.getInstance();
    final map = _readMap(prefs);
    map[alert.dismissKey()] = (
      dismissedAtMs: dismissedAt.millisecondsSinceEpoch,
      fingerprint: alert.dismissFingerprint(),
    );
    await _writeMap(prefs, map);
  }

  @override
  Future<void> clearForLibrary(String libraryId) async {
    final prefs = await SharedPreferences.getInstance();
    final map = _readMap(prefs);
    map.removeWhere((key, _) => key.startsWith('$libraryId:'));
    await _writeMap(prefs, map);
  }

  Future<void> _writeMap(
    SharedPreferences prefs,
    Map<String, HomeAlertDismissEntry> map,
  ) async {
    final Map<String, Map<String, Object>> encoded = map.map(
      (String key, HomeAlertDismissEntry entry) =>
          MapEntry<String, Map<String, Object>>(key, <String, Object>{
            'dismissedAtMs': entry.dismissedAtMs,
            'fingerprint': entry.fingerprint,
          }),
    );
    await prefs.setString(_kHomeAlertDismissedKey, jsonEncode(encoded));
  }

  Map<String, HomeAlertDismissEntry> _readMap(SharedPreferences prefs) {
    final String? raw = prefs.getString(_kHomeAlertDismissedKey);
    if (raw == null || raw.isEmpty) {
      return <String, HomeAlertDismissEntry>{};
    }
    try {
      final Object? decoded = jsonDecode(raw);
      if (decoded is! Map) {
        return <String, HomeAlertDismissEntry>{};
      }
      return Map<String, HomeAlertDismissEntry>.fromEntries(
        decoded.entries.map((MapEntry<dynamic, dynamic> entry) {
          final Object? value = entry.value;
          if (value is int) {
            return MapEntry<String, HomeAlertDismissEntry>(
              entry.key.toString(),
              (dismissedAtMs: value, fingerprint: ''),
            );
          }
          if (value is Map) {
            return MapEntry<String, HomeAlertDismissEntry>(
              entry.key.toString(),
              (
                dismissedAtMs: value['dismissedAtMs'] is int
                    ? value['dismissedAtMs'] as int
                    : int.tryParse('${value['dismissedAtMs']}') ?? 0,
                fingerprint: '${value['fingerprint'] ?? ''}',
              ),
            );
          }
          return MapEntry<String, HomeAlertDismissEntry>(entry.key.toString(), (
            dismissedAtMs: 0,
            fingerprint: '',
          ));
        }),
      );
    } catch (_) {
      return <String, HomeAlertDismissEntry>{};
    }
  }
}
