import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/core/async/cancellation_token.dart';
import 'package:hentai_library/design-system/design_system.dart';
import 'package:hentai_library/features/app_settings/application/app_update_gateway.dart';
import 'package:hentai_library/features/app_settings/domain/app_release_info.dart';
import 'package:hentai_library/features/app_settings/domain/app_setting.dart';
import 'package:hentai_library/features/app_settings/presentation/providers/app_setting_repository_provider.dart';
import 'package:hentai_library/features/app_settings/presentation/providers/app_update_providers.dart';
import 'package:hentai_library/features/app_settings/presentation/providers/installed_app_version_providers.dart';
import 'package:hentai_library/features/app_settings/presentation/view_models/app_update_controller.dart';
import 'package:hentai_library/features/app_settings/presentation/view_models/settings_notifier.dart';
import 'package:hentai_library/features/app_settings/presentation/views/dialogs/app_update_dialog.dart';
import 'package:hentai_library/l10n/app_localizations.dart';

import '../../../../support/fakes/settings_test_fakes.dart';
import '../../../../support/pump_localized_app.dart';

void main() {
  test(
    'provider is lazy and checks read dismissal changed during the request',
    () async {
      final response = Completer<AppReleaseInfo?>();
      final requested = Completer<void>();
      final gateway = _Gateway(() {
        if (!requested.isCompleted) requested.complete();
        return response.future;
      });
      final container = _container(gateway);
      await container.read(settingsProvider.future);
      container.read(checkAppUpdateUseCaseProvider);
      final controller = container.read(appUpdateControllerProvider.notifier);
      expect(gateway.calls, 0);

      final pending = controller.checkForUpdate(
        respectDismissedVersion: true,
        showDialogOnUpdate: false,
        showFeedbackToasts: false,
      );
      await requested.future;
      await container
          .read(settingsProvider.notifier)
          .setDismissedUpdateVersion('2.0.0');
      response.complete(_release());
      expect(await pending, AppUpdateCheckOutcome.upToDate);
      expect(
        await controller.checkForUpdate(
          respectDismissedVersion: false,
          showDialogOnUpdate: false,
          showFeedbackToasts: false,
        ),
        AppUpdateCheckOutcome.updateAvailable,
      );
      expect(gateway.calls, 2);
    },
  );

  test(
    'missing releases and network errors map to a failed UI outcome',
    () async {
      final gateway = _Gateway(() async => null);
      final container = _container(gateway);
      final controller = container.read(appUpdateControllerProvider.notifier);
      expect(
        await controller.checkForUpdate(
          respectDismissedVersion: false,
          showDialogOnUpdate: false,
          showFeedbackToasts: false,
        ),
        AppUpdateCheckOutcome.failed,
      );
      gateway.fetch = () async => throw StateError('network');
      expect(
        await controller.checkForUpdate(
          respectDismissedVersion: false,
          showDialogOnUpdate: false,
          showFeedbackToasts: false,
        ),
        AppUpdateCheckOutcome.failed,
      );
      expect(gateway.calls, 2);
    },
  );

  test('installed-version errors fail before requesting a release', () async {
    final gateway = _Gateway(() async => _release());
    final container = _container(
      gateway,
      versionQuery: () async => throw StateError('native version'),
    );
    expect(
      await container
          .read(appUpdateControllerProvider.notifier)
          .checkForUpdate(
            respectDismissedVersion: false,
            showDialogOnUpdate: false,
            showFeedbackToasts: false,
          ),
      AppUpdateCheckOutcome.failed,
    );
    expect(gateway.calls, 0);
  });

  testWidgets(
    'current versions show feedback while dismissed updates stay silent',
    (tester) async {
      var latest = _release('1.0.0');
      final container = _container(_Gateway(() async => latest));
      await container.read(settingsProvider.future);
      late BuildContext context;
      await pumpLocalizedApp(
        tester,
        home: Builder(
          builder: (value) {
            context = value;
            return const Scaffold();
          },
        ),
      );
      final l10n = AppLocalizations.of(context);
      final controller = container.read(appUpdateControllerProvider.notifier);
      expect(
        await controller.checkForUpdate(
          respectDismissedVersion: true,
          showDialogOnUpdate: true,
          showFeedbackToasts: true,
          feedback: appUpdateFeedback(context),
        ),
        AppUpdateCheckOutcome.upToDate,
      );
      await tester.pumpAndSettle();
      expect(find.text(l10n.settingsUpdateUpToDate), findsOneWidget);
      await tester.pump(kAppSnackbarDefaultDuration);
      await tester.pumpAndSettle();
      expect(find.text(l10n.settingsUpdateUpToDate), findsNothing);

      latest = _release();
      await container
          .read(settingsProvider.notifier)
          .setDismissedUpdateVersion('2.0.0');
      expect(
        await controller.checkForUpdate(
          respectDismissedVersion: true,
          showDialogOnUpdate: true,
          showFeedbackToasts: true,
          feedback: appUpdateFeedback(context),
        ),
        AppUpdateCheckOutcome.upToDate,
      );
      await tester.pumpAndSettle();
      expect(find.text(l10n.settingsUpdateUpToDate), findsNothing);
      expect(find.byType(AppUpdateDialog), findsNothing);
    },
  );

  testWidgets('manual checks offer the release even after dismissal', (
    tester,
  ) async {
    final release = _release();
    final gateway = _Gateway(() async => release);
    final container = _container(gateway);
    await container.read(settingsProvider.future);
    await container
        .read(settingsProvider.notifier)
        .setDismissedUpdateVersion(release.version);
    late BuildContext context;
    await pumpLocalizedApp(
      tester,
      home: UncontrolledProviderScope(
        container: container,
        child: Builder(
          builder: (value) {
            context = value;
            return const Scaffold();
          },
        ),
      ),
    );
    final pending = container
        .read(appUpdateControllerProvider.notifier)
        .runManualCheck(feedback: appUpdateFeedback(context));
    await tester.pumpAndSettle();
    expect(find.byType(AppUpdateDialog), findsOneWidget);
    expect(
      tester.widget<AppUpdateDialog>(find.byType(AppUpdateDialog)).release,
      same(release),
    );
    Navigator.of(tester.element(find.byType(AppUpdateDialog))).pop();
    await tester.pumpAndSettle();
    await pending;
    expect(gateway.calls, 1);
  });

  testWidgets('a detached manual-check context receives no delayed UI', (
    tester,
  ) async {
    final response = Completer<AppReleaseInfo?>();
    final requested = Completer<void>();
    final gateway = _Gateway(() {
      requested.complete();
      return response.future;
    });
    final container = _container(gateway);
    late BuildContext context;
    await pumpLocalizedApp(
      tester,
      home: Builder(
        builder: (value) {
          context = value;
          return const Scaffold();
        },
      ),
    );
    final pending = container
        .read(appUpdateControllerProvider.notifier)
        .runManualCheck(feedback: appUpdateFeedback(context));
    await tester.pump();
    await requested.future;
    await tester.pumpWidget(const SizedBox.shrink());
    response.complete(_release());
    await tester.pumpAndSettle();
    await pending;
    expect(find.byType(AppUpdateDialog), findsNothing);
    expect(tester.takeException(), isNull);
    expect(gateway.calls, 1);
  });
}

ProviderContainer _container(
  _Gateway gateway, {
  Future<String> Function()? versionQuery,
}) {
  final container = ProviderContainer(
    retry: (_, _) => null,
    overrides: [
      appUpdateGatewayProvider.overrideWithValue(gateway),
      appSettingRepositoryProvider.overrideWithValue(
        MemoryAppSettingRepository(initial: AppSetting()),
      ),
      installedAppVersionQueryProvider.overrideWithValue(
        versionQuery ?? () async => '1.0.0',
      ),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

AppReleaseInfo _release([String version = '2.0.0']) => (
  version: version,
  publishedAt: DateTime.utc(2026),
  releaseNotes: ['Release notes'],
  htmlUrl: 'https://example.com/release',
  assets: [],
);

class _Gateway implements AppUpdateGateway {
  _Gateway(this.fetch);

  Future<AppReleaseInfo?> Function() fetch;
  var calls = 0;

  @override
  Future<AppReleaseInfo?> fetchLatestStableRelease() {
    calls++;
    return fetch();
  }

  @override
  AppReleaseAsset? findPlatformAsset(List<AppReleaseAsset> assets) =>
      throw UnimplementedError();

  @override
  Future<String> downloadAsset({
    required AppReleaseAsset asset,
    required void Function(int received, int total) onProgress,
    required CancellationToken cancelToken,
  }) => throw UnimplementedError();
}
