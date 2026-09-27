import 'dart:convert';

import 'package:hentai_library/domain/models/read_models/home_page_read_models.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'home_alert_dismiss_notifier.g.dart';

const String _kHomeAlertDismissedKey = 'home_alert_dismissed';

typedef HomeAlertDismissEntry = ({int dismissedAtMs, String fingerprint});

@Riverpod(keepAlive: true)
class HomeAlertDismissRevision extends _$HomeAlertDismissRevision {
  @override
  int build() => 0;

  void bump() => state++;
}

@Riverpod(keepAlive: true)
class HomeAlertDismissStore extends _$HomeAlertDismissStore {
  @override
  Future<Map<String, HomeAlertDismissEntry>> build() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return _readMap(prefs);
  }

  Future<void> dismiss(HomeLibraryAlert alert) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final Map<String, HomeAlertDismissEntry> map = _readMap(prefs);
    map[alert.dismissKey()] = (
      dismissedAtMs: DateTime.now().millisecondsSinceEpoch,
      fingerprint: alert.dismissFingerprint(),
    );
    await _writeMap(prefs, map);
    ref.invalidateSelf();
    ref.read(homeAlertDismissRevisionProvider.notifier).bump();
  }

  Future<void> clearForLibrary(String libraryId) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final Map<String, HomeAlertDismissEntry> map = _readMap(prefs);
    map.removeWhere((String key, _) => key.startsWith('$libraryId:'));
    await _writeMap(prefs, map);
    ref.invalidateSelf();
    ref.read(homeAlertDismissRevisionProvider.notifier).bump();
  }

  Future<void> clearForLibraryKind(String libraryId, HomeLibraryAlertKind kind) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final Map<String, HomeAlertDismissEntry> map = _readMap(prefs);
    map.remove('$libraryId:${kind.name}');
    await _writeMap(prefs, map);
    ref.invalidateSelf();
    ref.read(homeAlertDismissRevisionProvider.notifier).bump();
  }

  Future<void> _writeMap(
    SharedPreferences prefs,
    Map<String, HomeAlertDismissEntry> map,
  ) async {
    final Map<String, Map<String, Object>> encoded = map.map(
      (String key, HomeAlertDismissEntry entry) => MapEntry<String, Map<String, Object>>(
        key,
        <String, Object>{
          'dismissedAtMs': entry.dismissedAtMs,
          'fingerprint': entry.fingerprint,
        },
      ),
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
          return MapEntry<String, HomeAlertDismissEntry>(
            entry.key.toString(),
            (dismissedAtMs: 0, fingerprint: ''),
          );
        }),
      );
    } catch (_) {
      return <String, HomeAlertDismissEntry>{};
    }
  }
}

List<HomeLibraryAlert> filterDismissedHomeAlerts({
  required List<HomeLibraryAlert> alerts,
  required Map<String, HomeAlertDismissEntry> dismissed,
}) {
  if (dismissed.isEmpty) {
    return alerts;
  }
  return alerts
      .where((HomeLibraryAlert alert) {
        final HomeAlertDismissEntry? entry = dismissed[alert.dismissKey()];
        if (entry == null) {
          return true;
        }
        if (entry.fingerprint.isEmpty) {
          return false;
        }
        return entry.fingerprint != alert.dismissFingerprint();
      })
      .toList(growable: false);
}
