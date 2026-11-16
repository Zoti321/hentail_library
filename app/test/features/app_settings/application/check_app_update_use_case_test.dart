import 'dart:async';

import 'package:hentai_library/features/app_settings/application/check_app_update_use_case.dart';
import 'package:hentai_library/features/app_settings/domain/app_release_info.dart';
import 'package:test/test.dart';

void main() {
  test(
    'construction is lazy and every check fetches a fresh release',
    () async {
      var calls = 0;
      AppReleaseInfo? latest;
      final check = CheckAppUpdateUseCase(
        fetchLatestRelease: () async {
          calls++;
          return latest;
        },
        readDismissedVersion: () =>
            throw StateError('unexpected preference read'),
      );
      expect(calls, 0);
      expect(
        await check(currentVersion: '1.0.0', respectDismissedVersion: true),
        isA<AppUpdateUnavailable>(),
      );
      latest = _release('2.0.0');
      final result = await check(
        currentVersion: '1.0.0',
        respectDismissedVersion: false,
      );
      expect((result as AppUpdateAvailable).release, same(latest));
      expect(calls, 2);
    },
  );

  for (final current in ['V2.0.0+42', '3.0.0', '2.0']) {
    test(
      'installed $current is current without consulting dismissal',
      () async {
        final check = CheckAppUpdateUseCase(
          fetchLatestRelease: () async => _release('v2.0.0'),
          readDismissedVersion: () =>
              throw StateError('unexpected preference read'),
        );
        expect(
          await check(currentVersion: current, respectDismissedVersion: true),
          isA<AppUpdateCurrent>(),
        );
      },
    );
  }

  test(
    'dismissal is read after the network response, not at construction',
    () async {
      final response = Completer<AppReleaseInfo?>();
      String? dismissed;
      var reads = 0;
      final check = CheckAppUpdateUseCase(
        fetchLatestRelease: () => response.future,
        readDismissedVersion: () {
          reads++;
          return dismissed;
        },
      );
      final pending = check(
        currentVersion: '1.0.0',
        respectDismissedVersion: true,
      );
      expect(reads, 0);
      dismissed = 'v2.0.0';
      response.complete(_release('v2.0.0'));
      expect(await pending, isA<AppUpdateDismissed>());
      expect(reads, 1);
    },
  );

  for (final dismissed in <String?>[null, '1.5.0', '2.0.0']) {
    test(
      'offers v2.0.0 when the exact version is not dismissed: $dismissed',
      () async {
        final check = CheckAppUpdateUseCase(
          fetchLatestRelease: () async => _release('v2.0.0'),
          readDismissedVersion: () => dismissed,
        );
        expect(
          await check(currentVersion: '1.0.0', respectDismissedVersion: true),
          isA<AppUpdateAvailable>(),
        );
      },
    );
  }

  test(
    'request failures propagate without reading preferences or retrying',
    () async {
      final failure = StateError('network');
      var calls = 0;
      final check = CheckAppUpdateUseCase(
        fetchLatestRelease: () async {
          calls++;
          throw failure;
        },
        readDismissedVersion: () =>
            throw StateError('unexpected preference read'),
      );
      await expectLater(
        check(currentVersion: '1.0.0', respectDismissedVersion: true),
        throwsA(same(failure)),
      );
      expect(calls, 1);
    },
  );
}

AppReleaseInfo _release(String version) => (
  version: version,
  publishedAt: DateTime.utc(2026),
  releaseNotes: ['Release notes'],
  htmlUrl: 'https://example.com/release',
  assets: [],
);
