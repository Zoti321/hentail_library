import 'package:flutter/widgets.dart';
import 'package:hentai_library/core/l10n/app_localizations.dart';
import 'package:material_symbols_icons/symbols.dart';

/// Lab settings categories (aligned with production groups).
enum SettingsCategory { personalization, metadataBackup, diagnostics, about }

/// Master list metadata for [SettingsCategory].
class SettingsCategoryInfo {
  const SettingsCategoryInfo({required this.category, required this.icon});

  final SettingsCategory category;
  final IconData icon;

  String label(AppLocalizations l10n) {
    return switch (category) {
      SettingsCategory.personalization => l10n.settingsGroupPersonalization,
      SettingsCategory.metadataBackup => l10n.settingsGroupMetadataBackup,
      SettingsCategory.diagnostics => l10n.settingsGroupDiagnostics,
      SettingsCategory.about => l10n.settingsGroupAbout,
    };
  }

  String description(AppLocalizations l10n) {
    return switch (category) {
      SettingsCategory.personalization =>
        '${l10n.settingsThemeLabel} · ${l10n.readerSettingsReadingMode}',
      SettingsCategory.metadataBackup =>
        l10n.settingsMetadataBackupAutoToggleDescription,
      SettingsCategory.diagnostics =>
        '${l10n.settingsDiagnosticModeLabel} · ${l10n.settingsExportLogsLabel}',
      SettingsCategory.about =>
        '${l10n.settingsAutoUpdateLabel} · ${l10n.settingsCheckForUpdatesLabel}',
    };
  }
}

const List<SettingsCategoryInfo> kSettingsCategories = <SettingsCategoryInfo>[
  SettingsCategoryInfo(
    category: SettingsCategory.personalization,
    icon: Symbols.palette,
  ),
  SettingsCategoryInfo(
    category: SettingsCategory.metadataBackup,
    icon: Symbols.backup,
  ),
  SettingsCategoryInfo(
    category: SettingsCategory.diagnostics,
    icon: Symbols.bug_report,
  ),
  SettingsCategoryInfo(category: SettingsCategory.about, icon: Symbols.info),
];
