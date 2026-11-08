import 'package:flutter/widgets.dart';
import 'package:hentai_library/core/l10n/app_localizations.dart';
import 'package:material_symbols_icons/symbols.dart';

/// Lab / 生产设置分类（与 master 列表子项对齐）。
enum SettingsCategory {
  appearance,
  interface,
  reading,
  libraryBrowse,
  metadataBackup,
  about,
  updates,
  storageAndLogs,
}

/// Master 列表标题分组。
enum SettingsMasterGroup { app, libraryAdmin, other }

/// 一个 master 分组及其子分类。
class SettingsMasterGroupInfo {
  const SettingsMasterGroupInfo({
    required this.group,
    required this.categories,
  });

  final SettingsMasterGroup group;
  final List<SettingsCategory> categories;

  String label(AppLocalizations l10n) {
    return switch (group) {
      SettingsMasterGroup.app => l10n.settingsMasterGroupApp,
      SettingsMasterGroup.libraryAdmin => l10n.settingsMasterGroupLibraryAdmin,
      SettingsMasterGroup.other => l10n.settingsMasterGroupOther,
    };
  }
}

/// Master list metadata for [SettingsCategory].
class SettingsCategoryInfo {
  const SettingsCategoryInfo({required this.category, required this.icon});

  final SettingsCategory category;
  final IconData icon;

  String label(AppLocalizations l10n) {
    return switch (category) {
      SettingsCategory.appearance => l10n.settingsGroupAppearance,
      SettingsCategory.interface => l10n.settingsGroupInterface,
      SettingsCategory.reading => l10n.settingsGroupReading,
      SettingsCategory.libraryBrowse => l10n.settingsGroupLibraryBrowse,
      SettingsCategory.metadataBackup => l10n.settingsGroupMetadataBackup,
      SettingsCategory.about => l10n.settingsGroupAbout,
      SettingsCategory.updates => l10n.settingsGroupUpdates,
      SettingsCategory.storageAndLogs => l10n.settingsGroupStorageAndLogs,
    };
  }

  String description(AppLocalizations l10n) {
    return switch (category) {
      SettingsCategory.appearance =>
        '${l10n.settingsThemeLabel} · ${l10n.settingsColorSchemeLabel}',
      SettingsCategory.interface =>
        '${l10n.settingsLanguageLabel} · ${l10n.settingsFontLabel}',
      SettingsCategory.reading =>
        '${l10n.readerSettingsReadingMode} · ${l10n.readerSettingsAutoPlay}',
      SettingsCategory.libraryBrowse =>
        '${l10n.settingsHealthyModeLabel} · ${l10n.settingsPreferLibraryRootSeriesLabel}',
      SettingsCategory.metadataBackup =>
        l10n.settingsMetadataBackupAutoToggleDescription,
      SettingsCategory.about =>
        l10n.settingsMetadataBackupImportManifestAppVersion,
      SettingsCategory.updates =>
        '${l10n.settingsAutoUpdateLabel} · ${l10n.settingsCheckForUpdatesLabel}',
      SettingsCategory.storageAndLogs =>
        '${l10n.settingsDiagnosticModeLabel} · ${l10n.settingsExportLogsLabel}',
    };
  }
}

const List<SettingsCategoryInfo> kSettingsCategories = <SettingsCategoryInfo>[
  SettingsCategoryInfo(
    category: SettingsCategory.appearance,
    icon: Symbols.palette,
  ),
  SettingsCategoryInfo(
    category: SettingsCategory.interface,
    icon: Symbols.tune,
  ),
  SettingsCategoryInfo(
    category: SettingsCategory.reading,
    icon: Symbols.menu_book,
  ),
  SettingsCategoryInfo(
    category: SettingsCategory.libraryBrowse,
    icon: Symbols.grid_view,
  ),
  SettingsCategoryInfo(
    category: SettingsCategory.metadataBackup,
    icon: Symbols.backup,
  ),
  SettingsCategoryInfo(category: SettingsCategory.about, icon: Symbols.info),
  SettingsCategoryInfo(
    category: SettingsCategory.updates,
    icon: Symbols.system_update,
  ),
  SettingsCategoryInfo(
    category: SettingsCategory.storageAndLogs,
    icon: Symbols.folder_managed,
  ),
];

const List<SettingsMasterGroupInfo> kSettingsMasterGroups =
    <SettingsMasterGroupInfo>[
      SettingsMasterGroupInfo(
        group: SettingsMasterGroup.app,
        categories: <SettingsCategory>[
          SettingsCategory.appearance,
          SettingsCategory.interface,
        ],
      ),
      SettingsMasterGroupInfo(
        group: SettingsMasterGroup.libraryAdmin,
        categories: <SettingsCategory>[
          SettingsCategory.reading,
          SettingsCategory.libraryBrowse,
          SettingsCategory.metadataBackup,
        ],
      ),
      SettingsMasterGroupInfo(
        group: SettingsMasterGroup.other,
        categories: <SettingsCategory>[
          SettingsCategory.about,
          SettingsCategory.updates,
          SettingsCategory.storageAndLogs,
        ],
      ),
    ];

/// 按 master 分组顺序展开的分类列表（用于转场方向等）。
List<SettingsCategory> settingsCategoryOrder({
  Set<SettingsCategory>? visibleCategories,
}) {
  return <SettingsCategory>[
    for (final SettingsMasterGroupInfo group in kSettingsMasterGroups)
      for (final SettingsCategory category in group.categories)
        if (visibleCategories == null || visibleCategories.contains(category))
          category,
  ];
}

SettingsCategoryInfo settingsCategoryInfo(SettingsCategory category) {
  return kSettingsCategories.firstWhere(
    (SettingsCategoryInfo e) => e.category == category,
  );
}
