import 'package:test/test.dart';
import 'package:hentai_library/features/home/domain/home_alert_dismissal.dart';
import 'package:hentai_library/features/home/domain/home_page_read_models.dart';

void main() {
  group('filterDismissedHomeAlerts', () {
    const HomeLibraryAlert alert = HomeLibraryAlert(
      libraryId: 'lib-1',
      displayName: '测试库',
      kind: HomeLibraryAlertKind.staleSync,
      staleDays: 3,
    );

    test('hides alert when fingerprint matches dismiss entry', () {
      final List<HomeLibraryAlert> filtered = filterDismissedHomeAlerts(
        alerts: const <HomeLibraryAlert>[alert],
        dismissed: <String, HomeAlertDismissEntry>{
          alert.dismissKey(): (
            dismissedAtMs: 1,
            fingerprint: alert.dismissFingerprint(),
          ),
        },
      );

      expect(filtered, isEmpty);
    });

    test('shows alert again when sync fingerprint changes', () {
      final List<HomeLibraryAlert> filtered = filterDismissedHomeAlerts(
        alerts: const <HomeLibraryAlert>[alert],
        dismissed: <String, HomeAlertDismissEntry>{
          alert.dismissKey(): (
            dismissedAtMs: 1,
            fingerprint: 'sync:0:old-error',
          ),
        },
      );

      expect(filtered, hasLength(1));
    });

    test(
      'legacy empty fingerprints hide alerts and unrelated entries do not',
      () {
        expect(
          filterDismissedHomeAlerts(
            alerts: [alert],
            dismissed: {
              alert.dismissKey(): (dismissedAtMs: 1, fingerprint: ''),
            },
          ),
          isEmpty,
        );
        expect(
          filterDismissedHomeAlerts(
            alerts: [alert],
            dismissed: {
              'other:syncFailed': (dismissedAtMs: 1, fingerprint: ''),
            },
          ),
          [alert],
        );
        expect(filterDismissedHomeAlerts(alerts: [alert], dismissed: {}), [
          alert,
        ]);
      },
    );
  });
}
