import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/features/home/domain/home_page_read_models.dart';
import 'package:hentai_library/features/home/infrastructure/repositories/home_alert_dismiss_repository_impl.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const repository = HomeAlertDismissRepositoryImpl();
  const alert = HomeLibraryAlert(
    libraryId: 'lib-1',
    displayName: 'Library',
    kind: HomeLibraryAlertKind.syncFailed,
    lastErrorMessage: 'offline',
  );

  test(
    'reads legacy timestamps and current entries without rewriting them',
    () async {
      final raw = jsonEncode({
        'legacy': 12,
        'current': {'dismissedAtMs': 34, 'fingerprint': 'sync:0:offline'},
        'string-time': {'dismissedAtMs': '56'},
        'invalid': false,
      });
      SharedPreferences.setMockInitialValues({'home_alert_dismissed': raw});
      expect(await repository.load(), {
        'legacy': (dismissedAtMs: 12, fingerprint: ''),
        'current': (dismissedAtMs: 34, fingerprint: 'sync:0:offline'),
        'string-time': (dismissedAtMs: 56, fingerprint: ''),
        'invalid': (dismissedAtMs: 0, fingerprint: ''),
      });
      expect(
        (await SharedPreferences.getInstance()).getString(
          'home_alert_dismissed',
        ),
        raw,
      );
    },
  );

  test(
    'missing, malformed and non-map payloads yield an empty snapshot',
    () async {
      for (final raw in <String?>[null, '', '{broken', '[]', 'null']) {
        SharedPreferences.setMockInitialValues({'home_alert_dismissed': ?raw});
        expect(await repository.load(), isEmpty, reason: '$raw');
      }
    },
  );

  test('dismiss preserves existing entries and clear matches the exact library prefix', () async {
    SharedPreferences.setMockInitialValues({
      'home_alert_dismissed': jsonEncode({
        'lib-1:staleSync': 1,
        'lib-10:syncFailed': 2,
        'other:syncFailed': 3,
      }),
      'unrelated': true,
    });
    await repository.dismiss(alert, DateTime.fromMillisecondsSinceEpoch(123));
    final saved = await repository.load();
    expect(saved[alert.dismissKey()], (
      dismissedAtMs: 123,
      fingerprint: alert.dismissFingerprint(),
    ));
    expect(saved, hasLength(4));
    await repository.clearForLibrary('lib-1');
    expect(
      (await repository.load()).keys,
      unorderedEquals(['lib-10:syncFailed', 'other:syncFailed']),
    );
    expect(
      (await SharedPreferences.getInstance()).getBool('unrelated'),
      isTrue,
    );
  });
}
