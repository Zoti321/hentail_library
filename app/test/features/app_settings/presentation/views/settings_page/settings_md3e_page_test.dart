import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/core/l10n/app_localizations.dart';
import 'package:hentai_library/core/l10n/app_localizations_x.dart';
import 'package:hentai_library/features/app_settings/presentation/view_models/settings_notifier.dart';
import 'package:hentai_library/features/app_settings/presentation/views/settings_page/settings_md3e_page.dart';
import 'package:hentai_library/features/app_settings/domain/app_setting.dart';

import '../../../../../support/pump_localized_app.dart';
import '../../../../../support/test_view.dart';

class _RecordingSettingsNotifier extends SettingsNotifier {
  final List<AppThemePreference> themeCalls = <AppThemePreference>[];
  final List<bool> healthyCalls = <bool>[];

  @override
  Future<AppSetting> build() async => AppSetting();

  @override
  Future<void> setThemePreference(AppThemePreference value) async {
    themeCalls.add(value);
  }

  @override
  Future<void> setHealthyMode(bool value) async {
    healthyCalls.add(value);
  }
}

Future<_RecordingSettingsNotifier> _pumpPage(WidgetTester tester) async {
  configureTestView(tester, const Size(1200, 900));

  final _RecordingSettingsNotifier notifier = _RecordingSettingsNotifier();
  final ProviderContainer container = ProviderContainer(
    overrides: [settingsProvider.overrideWith(() => notifier)],
  );
  addTearDown(container.dispose);
  await container.read(settingsProvider.future);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: buildLocalizedTestMaterialApp(
        home: const Scaffold(body: SettingsMd3ePage()),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return notifier;
}

void main() {
  testWidgets(
    'tapping theme tile opens a menu and persists the chosen preference',
    (WidgetTester tester) async {
      final _RecordingSettingsNotifier notifier = await _pumpPage(tester);
      final AppLocalizations l10n = lookupAppLocalizations(const Locale('zh'));
      expect(find.byKey(const Key('settings_md3e')), findsOneWidget);

      await tester.tap(find.text(l10n.settingsThemeLabel));
      await tester.pumpAndSettle();
      expect(notifier.themeCalls, isEmpty);

      await tester.tap(
        find.text(l10n.themePreferenceLabel(AppThemePreference.light)).last,
      );
      await tester.pumpAndSettle();

      expect(notifier.themeCalls, <AppThemePreference>[
        AppThemePreference.light,
      ]);
    },
  );

  testWidgets('toggling healthy mode persists through SettingsNotifier', (
    WidgetTester tester,
  ) async {
    final _RecordingSettingsNotifier notifier = await _pumpPage(tester);
    final AppLocalizations l10n = lookupAppLocalizations(const Locale('zh'));

    await tester.tap(find.text(l10n.settingsHealthyModeLabel));
    await tester.pumpAndSettle();

    expect(notifier.healthyCalls, <bool>[true]);
  });
}
