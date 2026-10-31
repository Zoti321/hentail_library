import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/core/l10n/app_localizations.dart';
import 'package:hentai_library/features/app_settings/presentation/view_models/settings_notifier.dart';
import 'package:hentai_library/features/app_settings/presentation/views/settings_page/settings_md3e_pilot_page.dart';
import 'package:hentai_library/shared/domain/models/app_setting.dart';

class _RecordingSettingsNotifier extends SettingsNotifier {
  final List<AppThemePreference> themeCalls = <AppThemePreference>[];

  @override
  Future<AppSetting> build() async => AppSetting();

  @override
  Future<void> setThemePreference(AppThemePreference value) async {
    themeCalls.add(value);
  }
}

void main() {
  testWidgets('tapping theme tile persists the next preference', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final _RecordingSettingsNotifier notifier = _RecordingSettingsNotifier();
    final ProviderContainer container = ProviderContainer(
      overrides: [settingsProvider.overrideWith(() => notifier)],
    );
    addTearDown(container.dispose);
    await container.read(settingsProvider.future);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          locale: const Locale('zh'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const Scaffold(body: SettingsMd3ePilotPage()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final AppLocalizations l10n = lookupAppLocalizations(const Locale('zh'));
    expect(find.byKey(const Key('settings_md3e_pilot')), findsOneWidget);

    await tester.tap(find.text(l10n.settingsThemeLabel));
    await tester.pumpAndSettle();

    expect(notifier.themeCalls, <AppThemePreference>[
      AppThemePreference.light,
    ]);
  });
}
