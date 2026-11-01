import 'package:flutter/widgets.dart';
import 'package:hentai_library/core/l10n/app_localizations.dart';
import 'package:material_symbols_icons/symbols.dart';

/// Lab settings categories (aligned with production groups).
enum Md3eSettingsCategory {
  personalization,
  metadataBackup,
  diagnostics,
  about,
}

/// Master list metadata for [Md3eSettingsCategory].
class Md3eSettingsCategoryInfo {
  const Md3eSettingsCategoryInfo({
    required this.category,
    required this.icon,
  });

  final Md3eSettingsCategory category;
  final IconData icon;

  String label(AppLocalizations l10n) {
    return switch (category) {
      Md3eSettingsCategory.personalization => l10n.settingsGroupPersonalization,
      Md3eSettingsCategory.metadataBackup => l10n.settingsGroupMetadataBackup,
      Md3eSettingsCategory.diagnostics => l10n.settingsGroupDiagnostics,
      Md3eSettingsCategory.about => l10n.settingsGroupAbout,
    };
  }

  String description(AppLocalizations l10n) {
    return switch (category) {
      Md3eSettingsCategory.personalization =>
        '${l10n.settingsThemeLabel} · ${l10n.settingsLanguageLabel}',
      Md3eSettingsCategory.metadataBackup =>
        l10n.settingsMetadataBackupAutoToggleDescription,
      Md3eSettingsCategory.diagnostics =>
        l10n.settingsDiagnosticModeDescriptionDisabled,
      Md3eSettingsCategory.about => l10n.settingsCheckForUpdatesLabel,
    };
  }
}

const List<Md3eSettingsCategoryInfo> kMd3eSettingsCategories =
    <Md3eSettingsCategoryInfo>[
      Md3eSettingsCategoryInfo(
        category: Md3eSettingsCategory.personalization,
        icon: Symbols.palette,
      ),
      Md3eSettingsCategoryInfo(
        category: Md3eSettingsCategory.metadataBackup,
        icon: Symbols.backup,
      ),
      Md3eSettingsCategoryInfo(
        category: Md3eSettingsCategory.diagnostics,
        icon: Symbols.bug_report,
      ),
      Md3eSettingsCategoryInfo(
        category: Md3eSettingsCategory.about,
        icon: Symbols.info,
      ),
    ];
