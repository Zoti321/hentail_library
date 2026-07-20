import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/core/l10n/app_localizations.dart';
import 'package:hentai_library/core/util/semver_utils.dart';
import 'package:hentai_library/data/services/app_update/app_update_service.dart';
import 'package:hentai_library/domain/models/app_release_info.dart';
import 'package:hentai_library/domain/models/app_setting.dart';
import 'package:hentai_library/ui/core/widgets/overlays/dialog/app_update_dialog.dart';
import 'package:hentai_library/ui/features/settings/state/app_update_controller.dart';
import 'package:hentai_library/ui/features/settings/view_models/settings_notifier.dart';
import 'package:hentai_library/ui/features/shell/di/services.dart';
import 'package:mocktail/mocktail.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:riverpod/misc.dart' show Override;

class MockAppUpdateService extends Mock implements AppUpdateService {}

void main() {
  group('SemverUtils', () {
    test('remote 0.0.1 is not greater than local 1.0.0', () {
      expect(SemverUtils.isGreaterThan('0.0.1', '1.0.0'), isFalse);
    });

    test('remote 1.0.1 is greater than local 1.0.0', () {
      expect(SemverUtils.isGreaterThan('1.0.1', '1.0.0'), isTrue);
    });
  });

  group('manual update check dialog', () {
    late MockAppUpdateService mockService;

    setUp(() {
      mockService = MockAppUpdateService();
    });

    testWidgets('shows dialog when remote version is newer', (
      WidgetTester tester,
    ) async {
      final AppReleaseInfo newerRelease = (
        version: '1.0.1',
        publishedAt: DateTime.utc(2026, 6, 27),
        releaseNotes: <String>['修复若干问题'],
        htmlUrl:
            'https://github.com/Zoti321/hentail_library/releases/tag/v1.0.1',
        assets: <AppReleaseAsset>[],
      );
      when(
        () => mockService.fetchLatestStableRelease(),
      ).thenAnswer((_) async => newerRelease);

      await tester.pumpWidget(_buildHarness(mockService: mockService));
      await tester.tap(find.text('检查更新'));
      await tester.pumpAndSettle();

      expect(find.byType(AppUpdateDialog), findsOneWidget);
      expect(find.text('发现新版本 v1.0.1'), findsOneWidget);
    });

    testWidgets(
      'shows toast instead of dialog when remote is older than local',
      (WidgetTester tester) async {
        final AppReleaseInfo olderRelease = (
          version: '0.0.1',
          publishedAt: DateTime.utc(2026, 4, 25),
          releaseNotes: <String>['windows'],
          htmlUrl:
              'https://github.com/Zoti321/hentail_library/releases/tag/0.0.1',
          assets: <AppReleaseAsset>[],
        );
        when(
          () => mockService.fetchLatestStableRelease(),
        ).thenAnswer((_) async => olderRelease);

        await tester.pumpWidget(_buildHarness(mockService: mockService));
        await tester.tap(find.text('检查更新'));
        await tester.pumpAndSettle();

        expect(find.byType(AppUpdateDialog), findsNothing);
        expect(find.text('当前已是最新版本'), findsOneWidget);
      },
    );

    testWidgets(
      'root navigator key alone does not show dialog without context param',
      (WidgetTester tester) async {
        final AppReleaseInfo newerRelease = (
          version: '1.0.1',
          publishedAt: DateTime.utc(2026, 6, 27),
          releaseNotes: <String>['修复若干问题'],
          htmlUrl:
              'https://github.com/Zoti321/hentail_library/releases/tag/v1.0.1',
          assets: <AppReleaseAsset>[],
        );
        when(
          () => mockService.fetchLatestStableRelease(),
        ).thenAnswer((_) async => newerRelease);

        await tester.pumpWidget(
          ProviderScope(
            overrides: _overrides(mockService),
            child: const MaterialApp(home: SizedBox.shrink()),
          ),
        );

        final ProviderContainer container = ProviderScope.containerOf(
          tester.element(find.byType(SizedBox)),
        );
        await container
            .read(appUpdateControllerProvider.notifier)
            .runManualCheck();
        await tester.pumpAndSettle();

        expect(find.byType(AppUpdateDialog), findsNothing);
      },
    );
  });
}

Widget _buildHarness({required MockAppUpdateService mockService}) {
  return ProviderScope(
    overrides: _overrides(mockService),
    child: MaterialApp(
      locale: const Locale('zh'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Builder(
        builder: (BuildContext context) {
          return ElevatedButton(
            onPressed: () async {
              await ProviderScope.containerOf(context)
                  .read(appUpdateControllerProvider.notifier)
                  .runManualCheck(context: context);
            },
            child: const Text('检查更新'),
          );
        },
      ),
    ),
  );
}

List<Override> _overrides(MockAppUpdateService mockService) {
  return [
    appUpdateServiceProvider.overrideWithValue(mockService),
    packageInfoProvider.overrideWith(
      (Ref ref) => Future<PackageInfo>.value(
        PackageInfo(
          appName: 'hentai_library',
          packageName: 'hentai_library',
          version: '1.0.0',
          buildNumber: '1',
          buildSignature: '',
          installerStore: '',
        ),
      ),
    ),
    settingsProvider.overrideWith(() => _FakeSettingsNotifier()),
  ];
}

class _FakeSettingsNotifier extends SettingsNotifier {
  @override
  Future<AppSetting> build() async => AppSetting();
}
