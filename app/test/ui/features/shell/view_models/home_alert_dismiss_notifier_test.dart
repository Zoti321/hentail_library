import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/domain/models/read_models/home_page_read_models.dart';
import 'package:hentai_library/ui/features/shell/view_models/home_alert_dismiss_notifier.dart';

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

    test('shows pending resources alert when probe count changes', () {
      const HomeLibraryAlert pending = HomeLibraryAlert(
        libraryId: 'lib-1',
        displayName: '测试库',
        kind: HomeLibraryAlertKind.pendingResourcesDetected,
        pendingResourceCount: 5,
      );

      final List<HomeLibraryAlert> filtered = filterDismissedHomeAlerts(
        alerts: const <HomeLibraryAlert>[pending],
        dismissed: <String, HomeAlertDismissEntry>{
          pending.dismissKey(): (
            dismissedAtMs: 1,
            fingerprint: 'probe:3',
          ),
        },
      );

      expect(filtered, hasLength(1));
    });
  });
}
