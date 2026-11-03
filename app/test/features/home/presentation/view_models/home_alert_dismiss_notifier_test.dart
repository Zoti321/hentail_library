import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/features/home/domain/home_page_read_models.dart';
import 'package:hentai_library/features/home/presentation/view_models/home_alert_dismiss_notifier.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  });

  group('HomeAlertDismissStore clear policy', () {
    const HomeLibraryAlert syncFailed = HomeLibraryAlert(
      libraryId: 'lib-1',
      displayName: '测试库',
      kind: HomeLibraryAlertKind.syncFailed,
      lastErrorMessage: 'disk',
    );

    setUp(() {
      SharedPreferences.setMockInitialValues(<String, Object>{});
    });

    test('sync from the alert clears every dismiss for that library', () async {
      final ProviderContainer container = ProviderContainer();
      addTearDown(container.dispose);
      final HomeAlertDismissStore store = container.read(
        homeAlertDismissStoreProvider.notifier,
      );
      await container.read(homeAlertDismissStoreProvider.future);
      await store.dismiss(syncFailed);

      await store.clearDismissAfterAlertSync(syncFailed.libraryId);

      final Map<String, HomeAlertDismissEntry> dismissed = await container.read(
        homeAlertDismissStoreProvider.future,
      );
      final List<HomeLibraryAlert> visible = filterDismissedHomeAlerts(
        alerts: const <HomeLibraryAlert>[syncFailed],
        dismissed: dismissed,
      );

      expect(visible, hasLength(1));
    });
  });
}
