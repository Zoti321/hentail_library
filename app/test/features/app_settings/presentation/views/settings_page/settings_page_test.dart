import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/core/l10n/app_localizations.dart';
import 'package:hentai_library/features/app_settings/presentation/view_models/settings_notifier.dart';
import 'package:hentai_library/features/app_settings/presentation/views/settings_page/settings_page.dart';
import 'package:hentai_library/features/app_settings/domain/app_setting.dart';
import 'package:hentai_library/shared/di/settings_slot_providers.dart';
import 'package:hentai_library/shared/domain/models/enums.dart';
import 'package:hentai_library/shared/ui/widgets/settings/settings_tile.dart';

import '../../../../../support/pump_localized_app.dart';

import 'package:hentai_library/features/app_settings/public/ui/l10n/app_settings_l10n.dart';
import 'package:hentai_library/features/library_browse/public/l10n/library_browse_l10n.dart';

class _RecordingSettingsNotifier extends SettingsNotifier {
  _RecordingSettingsNotifier({AppSetting? initial})
    : _initial = initial ?? AppSetting();

  final AppSetting _initial;
  final List<AppThemePreference> themeCalls = <AppThemePreference>[];
  final List<AppColorSchemePreference> colorSchemeCalls =
      <AppColorSchemePreference>[];
  final List<bool> dynamicColorCalls = <bool>[];
  final List<bool> healthyCalls = <bool>[];
  final List<LibraryDisplayTarget> defaultLibraryDisplayTargetCalls =
      <LibraryDisplayTarget>[];

  @override
  Future<AppSetting> build() async => _initial;

  @override
  Future<void> setThemePreference(AppThemePreference value) async {
    themeCalls.add(value);
  }

  @override
  Future<void> setColorSchemePreference(AppColorSchemePreference value) async {
    colorSchemeCalls.add(value);
  }

  @override
  Future<void> setUseDynamicColor(bool value) async {
    dynamicColorCalls.add(value);
    state = AsyncData<AppSetting>(_initial.copyWith(useDynamicColor: value));
  }

  @override
  Future<void> setHealthyMode(bool value) async {
    healthyCalls.add(value);
  }

  @override
  Future<void> setDefaultLibraryDisplayTarget(
    LibraryDisplayTarget value,
  ) async {
    defaultLibraryDisplayTargetCalls.add(value);
  }
}

Future<_RecordingSettingsNotifier> _pumpPage(
  WidgetTester tester, {
  AppSetting? initial,
}) async {
  configureTestView(tester, const Size(1200, 900));

  final _RecordingSettingsNotifier notifier = _RecordingSettingsNotifier(
    initial: initial,
  );
  final ProviderContainer container = ProviderContainer(
    overrides: [
      settingsProvider.overrideWith(() => notifier),
      metadataBackupSettingsSectionBuilderProvider.overrideWithValue(
        (BuildContext context) => const SizedBox.shrink(),
      ),
    ],
  );
  addTearDown(container.dispose);
  await container.read(settingsProvider.future);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: buildLocalizedTestMaterialApp(
        home: const Scaffold(body: SettingsPage()),
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
      expect(find.byKey(const Key('settings')), findsOneWidget);

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

  testWidgets(
    'tapping color scheme tile opens dialog and persists the chosen preference',
    (WidgetTester tester) async {
      final _RecordingSettingsNotifier notifier = await _pumpPage(tester);
      final AppLocalizations l10n = lookupAppLocalizations(const Locale('zh'));

      await tester.tap(find.text(l10n.settingsColorSchemeLabel));
      await tester.pumpAndSettle();
      expect(notifier.colorSchemeCalls, isEmpty);
      expect(find.byType(GridView), findsOneWidget);
      expect(find.byType(Card), findsWidgets);
      expect(find.byIcon(Icons.check_rounded), findsOneWidget);

      await tester.tap(find.text(l10n.colorSchemePreferenceTeal));
      await tester.pumpAndSettle();

      expect(notifier.colorSchemeCalls, <AppColorSchemePreference>[
        AppColorSchemePreference.teal,
      ]);
    },
  );

  testWidgets(
    'toggling dynamic color persists and disables color scheme tile',
    (WidgetTester tester) async {
      final _RecordingSettingsNotifier notifier = await _pumpPage(tester);
      final AppLocalizations l10n = lookupAppLocalizations(const Locale('zh'));

      await tester.tap(find.text(l10n.settingsDynamicColorLabel));
      await tester.pumpAndSettle();
      expect(notifier.dynamicColorCalls, <bool>[true]);

      final SettingsNavigationTile colorTile = tester.widget(
        find.widgetWithText(
          SettingsNavigationTile,
          l10n.settingsColorSchemeLabel,
        ),
      );
      expect(colorTile.enabled, isFalse);

      await tester.tap(find.text(l10n.settingsColorSchemeLabel));
      await tester.pumpAndSettle();
      expect(find.byType(GridView), findsNothing);
      expect(notifier.colorSchemeCalls, isEmpty);
    },
  );

  testWidgets('color scheme tile stays disabled when dynamic color is on', (
    WidgetTester tester,
  ) async {
    await _pumpPage(tester, initial: AppSetting(useDynamicColor: true));
    final AppLocalizations l10n = lookupAppLocalizations(const Locale('zh'));

    final SettingsNavigationTile colorTile = tester.widget(
      find.widgetWithText(
        SettingsNavigationTile,
        l10n.settingsColorSchemeLabel,
      ),
    );
    expect(colorTile.enabled, isFalse);
  });

  testWidgets('toggling healthy mode persists through SettingsNotifier', (
    WidgetTester tester,
  ) async {
    final _RecordingSettingsNotifier notifier = await _pumpPage(tester);
    final AppLocalizations l10n = lookupAppLocalizations(const Locale('zh'));

    await tester.tap(find.text(l10n.settingsGroupLibraryBrowse));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.settingsHealthyModeLabel));
    await tester.pumpAndSettle();

    expect(notifier.healthyCalls, <bool>[true]);
  });

  testWidgets(
    'appearance hosts font and language; interface hosts Default library display target',
    (WidgetTester tester) async {
      final _RecordingSettingsNotifier notifier = await _pumpPage(tester);
      final AppLocalizations l10n = lookupAppLocalizations(const Locale('zh'));

      expect(find.text(l10n.settingsFontLabel), findsOneWidget);
      expect(find.text(l10n.settingsLanguageLabel), findsOneWidget);
      expect(
        find.text(l10n.settingsDefaultLibraryDisplayTargetLabel),
        findsNothing,
      );

      await tester.tap(find.text(l10n.settingsGroupInterface));
      await tester.pumpAndSettle();

      expect(find.text(l10n.settingsFontLabel), findsNothing);
      expect(
        find.text(l10n.settingsDefaultLibraryDisplayTargetLabel),
        findsOneWidget,
      );

      await tester.tap(
        find.text(l10n.settingsDefaultLibraryDisplayTargetLabel),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find
            .text(
              l10n.libraryDisplayTargetTabLabel(LibraryDisplayTarget.series),
            )
            .last,
      );
      await tester.pumpAndSettle();

      expect(notifier.defaultLibraryDisplayTargetCalls, <LibraryDisplayTarget>[
        LibraryDisplayTarget.series,
      ]);
    },
  );
}
