import 'package:hentai_library/features/home/domain/home_alert_dismissal.dart';
import 'package:hentai_library/features/home/domain/home_alert_dismiss_repository.dart';
import 'package:hentai_library/features/home/infrastructure/repositories/home_alert_dismiss_repository_impl.dart';
import 'package:hentai_library/features/home/presentation/providers/home_alert_dismiss_repository_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/features/home/domain/home_page_read_models.dart';
import 'package:hentai_library/features/home/presentation/view_models/home_alert_dismiss_notifier.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test(
    'refreshes after committed writes and preserves state on storage failure',
    () async {
      final repository = _DismissRepository();
      final container = ProviderContainer(
        overrides: [
          homeAlertDismissRepositoryProvider.overrideWithValue(repository),
        ],
      );
      addTearDown(container.dispose);
      const alert = HomeLibraryAlert(
        libraryId: 'test',
        displayName: 'Library',
        kind: HomeLibraryAlertKind.staleSync,
      );
      final notifier = container.read(homeAlertDismissStoreProvider.notifier);
      expect(
        await container.read(homeAlertDismissStoreProvider.future),
        isEmpty,
      );
      await notifier.dismiss(alert);
      final snapshot = await container.read(
        homeAlertDismissStoreProvider.future,
      );
      expect(snapshot.keys, [alert.dismissKey()]);
      expect(repository.loads, 2);

      repository.fail = true;
      await expectLater(
        notifier.clearDismissAfterAlertSync('test'),
        throwsStateError,
      );
      expect(
        container.read(homeAlertDismissStoreProvider).requireValue,
        snapshot,
      );
      expect(repository.loads, 2);

      repository.fail = false;
      await notifier.clearDismissAfterAlertSync('test');
      expect(
        await container.read(homeAlertDismissStoreProvider.future),
        isEmpty,
      );
      expect(repository.loads, 3);
    },
  );

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
      final ProviderContainer container = ProviderContainer(
        overrides: [
          homeAlertDismissRepositoryProvider.overrideWithValue(
            const HomeAlertDismissRepositoryImpl(),
          ),
        ],
      );
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

class _DismissRepository implements HomeAlertDismissRepository {
  var entries = <String, HomeAlertDismissEntry>{};
  var loads = 0;
  var fail = false;

  @override
  Future<Map<String, HomeAlertDismissEntry>> load() async {
    loads++;
    return Map.of(entries);
  }

  @override
  Future<void> dismiss(HomeLibraryAlert alert, DateTime dismissedAt) async {
    entries[alert.dismissKey()] = (
      dismissedAtMs: dismissedAt.millisecondsSinceEpoch,
      fingerprint: alert.dismissFingerprint(),
    );
  }

  @override
  Future<void> clearForLibrary(String libraryId) async {
    if (fail) throw StateError('storage unavailable');
    entries.removeWhere((key, _) => key.startsWith('$libraryId:'));
  }
}
