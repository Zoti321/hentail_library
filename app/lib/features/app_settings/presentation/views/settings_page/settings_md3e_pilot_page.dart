import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/core/l10n/app_localizations.dart';
import 'package:hentai_library/core/l10n/app_localizations_x.dart';
import 'package:hentai_library/features/app_settings/presentation/view_models/diagnostic_mode_notifier.dart';
import 'package:hentai_library/features/app_settings/presentation/view_models/settings_notifier.dart';
import 'package:hentai_library/md3e/pages/md3e_settings_page.dart';
import 'package:hentai_library/md3e/patterns/settings/md3e_settings_catalog.dart';
import 'package:hentai_library/md3e/theme/md3e_theme.dart';
import 'package:hentai_library/shared/domain/models/app_setting.dart';
import 'package:hentai_library/shared/domain/reading/reading_mode.dart';

/// Pilot 可见分类：metadataBackup 的 tile 均未接入业务，整组暂不展示。
const Set<Md3eSettingsCategory> kSettingsMd3ePilotCategories =
    <Md3eSettingsCategory>{
      Md3eSettingsCategory.personalization,
      Md3eSettingsCategory.diagnostics,
      Md3eSettingsCategory.about,
    };

/// 由 l10n 生成 Lab 选项文案，顺序与枚举 `values` 一致。
Md3eSettingsOptionLabels buildSettingsMd3ePilotOptionLabels(
  AppLocalizations l10n,
) {
  return Md3eSettingsOptionLabels(
    themeOptions: <String>[
      for (final AppThemePreference value in AppThemePreference.values)
        l10n.themePreferenceLabel(value),
    ],
    localeOptions: <String>[
      for (final AppLocalePreference value in AppLocalePreference.values)
        l10n.localePreferenceLabel(value),
    ],
    readingModeOptions: <String>[
      for (final ReadingMode value in ReadingMode.values)
        l10n.readingModeLabel(value),
    ],
  );
}

/// 生产设置 → Md3e 展示状态。
Md3eSettingsLabState buildSettingsMd3ePilotLabState({
  required AppSetting setting,
  required bool diagnosticMode,
  required Md3eSettingsOptionLabels labels,
}) {
  return Md3eSettingsLabState(
    themeLabel:
        labels.themeOptions[AppThemePreference.values.indexOf(
          setting.themePreference,
        )],
    localeLabel:
        labels.localeOptions[AppLocalePreference.values.indexOf(
          setting.localePreference,
        )],
    readingModeLabel: labels
        .readingModeOptions[ReadingMode.values.indexOf(setting.readingMode)],
    autoUpdate: setting.autoUpdate,
    diagnosticMode: diagnosticMode,
    // 生产中无对应存储，Pilot 不展示，固定为默认值。
    autoMetadataBackup: false,
    healthyMode: false,
  );
}

/// Md3e 选项文案 → 生产枚举（按文案在选项列表中的位置反查）。
AppThemePreference settingsMd3ePilotThemeFromLabel(
  Md3eSettingsOptionLabels labels,
  String label,
) {
  return AppThemePreference.values[labels.themeOptions.indexOf(label)];
}

/// Md3e 选项文案 → 生产枚举（按文案在选项列表中的位置反查）。
AppLocalePreference settingsMd3ePilotLocaleFromLabel(
  Md3eSettingsOptionLabels labels,
  String label,
) {
  return AppLocalePreference.values[labels.localeOptions.indexOf(label)];
}

/// Md3e 选项文案 → 生产阅读模式（按文案在选项列表中的位置反查）。
ReadingMode settingsMd3ePilotReadingModeFromLabel(
  Md3eSettingsOptionLabels labels,
  String label,
) {
  return ReadingMode.values[labels.readingModeOptions.indexOf(label)];
}

/// 设置页 Pilot：用真实 [SettingsNotifier] 与诊断开关驱动 MD3E 设置页。
class SettingsMd3ePilotPage extends ConsumerWidget {
  const SettingsMd3ePilotPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<AppSetting> settingsAsync = ref.watch(settingsProvider);
    final AppSetting? setting = settingsAsync.asData?.value;
    if (setting == null) {
      if (settingsAsync.hasError) {
        return Center(
          child: Text(
            settingsAsync.error.toString(),
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        );
      }
      return const Center(child: CircularProgressIndicator());
    }

    final bool diagnosticMode = ref.watch(diagnosticModeProvider);
    final Md3eSettingsOptionLabels labels = buildSettingsMd3ePilotOptionLabels(
      context.l10n,
    );
    final Md3eSettingsLabState labState = buildSettingsMd3ePilotLabState(
      setting: setting,
      diagnosticMode: diagnosticMode,
      labels: labels,
    );

    return Md3eThemeScope(
      child: Md3eSettingsPage(
        key: const Key('settings_md3e_pilot'),
        labState: labState,
        optionLabels: labels,
        showUnwiredTiles: false,
        visibleCategories: kSettingsMd3ePilotCategories,
        onLabStateChanged: (Md3eSettingsLabState next) {
          _applyChange(ref, labState, next, labels);
        },
      ),
    );
  }

  void _applyChange(
    WidgetRef ref,
    Md3eSettingsLabState previous,
    Md3eSettingsLabState next,
    Md3eSettingsOptionLabels labels,
  ) {
    final SettingsNotifier settings = ref.read(settingsProvider.notifier);
    if (next.themeLabel != previous.themeLabel) {
      settings.setThemePreference(
        settingsMd3ePilotThemeFromLabel(labels, next.themeLabel),
      );
    }
    if (next.localeLabel != previous.localeLabel) {
      settings.setLocalePreference(
        settingsMd3ePilotLocaleFromLabel(labels, next.localeLabel),
      );
    }
    if (next.readingModeLabel != previous.readingModeLabel) {
      settings.setReadingMode(
        settingsMd3ePilotReadingModeFromLabel(labels, next.readingModeLabel),
      );
    }
    if (next.autoUpdate != previous.autoUpdate) {
      settings.setAutoUpdate(next.autoUpdate);
    }
    if (next.diagnosticMode != previous.diagnosticMode) {
      ref.read(diagnosticModeProvider.notifier).setEnabled(next.diagnosticMode);
    }
  }
}
