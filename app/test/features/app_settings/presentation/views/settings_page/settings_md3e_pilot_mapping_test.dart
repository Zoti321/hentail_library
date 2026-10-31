import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/core/l10n/app_localizations.dart';
import 'package:hentai_library/features/app_settings/presentation/views/settings_page/settings_md3e_pilot_page.dart';
import 'package:hentai_library/md3e/patterns/settings/md3e_settings_catalog.dart';
import 'package:hentai_library/md3e/patterns/settings/md3e_settings_detail_panes.dart';
import 'package:hentai_library/shared/domain/models/app_setting.dart';
import 'package:hentai_library/shared/domain/reading/reading_mode.dart';

void main() {
  final AppLocalizations l10n = lookupAppLocalizations(const Locale('zh'));
  final Md3eSettingsOptionLabels labels = buildSettingsMd3ePilotOptionLabels(
    l10n,
  );

  test('option labels cover every production enum value in order', () {
    expect(labels.themeOptions, hasLength(AppThemePreference.values.length));
    expect(labels.localeOptions, hasLength(AppLocalePreference.values.length));
    expect(labels.readingModeOptions, hasLength(ReadingMode.values.length));
  });

  test('settings map to label state with real values', () {
    final AppSetting setting = AppSetting(
      themePreference: AppThemePreference.dark,
      localePreference: AppLocalePreference.en,
      readingMode: ReadingMode.webtoon,
      autoUpdate: false,
    );

    final Md3eSettingsLabState state = buildSettingsMd3ePilotLabState(
      setting: setting,
      diagnosticMode: true,
      labels: labels,
    );

    expect(state.themeLabel, labels.themeOptions[2]);
    expect(state.localeLabel, labels.localeOptions[2]);
    expect(state.readingModeLabel, labels.readingModeOptions[1]);
    expect(state.autoUpdate, isFalse);
    expect(state.diagnosticMode, isTrue);
    expect(state.healthyMode, isFalse);
    expect(state.autoMetadataBackup, isFalse);
  });

  test('label changes round-trip back to production enums', () {
    for (final AppThemePreference value in AppThemePreference.values) {
      final String label = labels.themeOptions[value.index];
      expect(settingsMd3ePilotThemeFromLabel(labels, label), value);
    }
    for (final AppLocalePreference value in AppLocalePreference.values) {
      final String label = labels.localeOptions[value.index];
      expect(settingsMd3ePilotLocaleFromLabel(labels, label), value);
    }
    for (final ReadingMode value in ReadingMode.values) {
      final String label = labels.readingModeOptions[value.index];
      expect(settingsMd3ePilotReadingModeFromLabel(labels, label), value);
    }
  });

  test('pilot shows only wired categories', () {
    expect(
      kSettingsMd3ePilotCategories,
      isNot(contains(Md3eSettingsCategory.metadataBackup)),
    );
    expect(
      kSettingsMd3ePilotCategories,
      containsAll(<Md3eSettingsCategory>[
        Md3eSettingsCategory.personalization,
        Md3eSettingsCategory.diagnostics,
        Md3eSettingsCategory.about,
      ]),
    );
  });

  test('nextMd3eOption cycles through options and wraps', () {
    const List<String> options = <String>['a', 'b', 'c'];
    expect(nextMd3eOption('a', options), 'b');
    expect(nextMd3eOption('c', options), 'a');
  });
}
