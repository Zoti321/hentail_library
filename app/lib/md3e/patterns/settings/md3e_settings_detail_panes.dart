import 'package:flutter/material.dart';
import 'package:hentai_library/md3e/l10n/md3e_l10n.dart';
import 'package:hentai_library/md3e/layout/md3e_settings_page_metrics.dart';
import 'package:hentai_library/md3e/patterns/settings/md3e_settings_catalog.dart';
import 'package:hentai_library/md3e/widgets/settings/md3e_settings_list.dart';
import 'package:hentai_library/md3e/widgets/settings/md3e_settings_tile.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_symbols_icons/symbols.dart';

/// Detail pane for one [Md3eSettingsCategory] (Lab stateful mocks).
class Md3eSettingsDetailPane extends StatelessWidget {
  const Md3eSettingsDetailPane({
    super.key,
    required this.category,
    required this.showTitle,
    required this.labState,
    required this.onLabStateChanged,
  });

  final Md3eSettingsCategory category;
  final bool showTitle;
  final Md3eSettingsLabState labState;
  final ValueChanged<Md3eSettingsLabState> onLabStateChanged;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final Md3eSettingsCategoryInfo info = kMd3eSettingsCategories.firstWhere(
      (Md3eSettingsCategoryInfo e) => e.category == category,
    );
    final Widget body = Md3eSettingsList(
      maxWidth: Md3eSettingsPageMetrics.detailListMaxWidth,
      sections: _sectionsForCategory(
        context,
        category,
        labState,
        onLabStateChanged,
      ),
    );

    if (!showTitle) {
      return body;
    }

    final M3EThemeData theme = M3ETheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Text(
            info.label(l10n),
            style: theme.typeScale.headlineSmall.copyWith(
              color: theme.colorScheme.onSurface,
            ),
          ),
        ),
        Expanded(child: body),
      ],
    );
  }
}

List<Widget> _sectionsForCategory(
  BuildContext context,
  Md3eSettingsCategory category,
  Md3eSettingsLabState labState,
  ValueChanged<Md3eSettingsLabState> onChanged,
) {
  final AppLocalizations l10n = context.l10n;
  return switch (category) {
    Md3eSettingsCategory.personalization => <Widget>[
      Md3eSettingsSection(
        tiles: <Widget>[
          Md3eSettingsNavigationTile(
            leading: Symbols.dark_mode,
            title: Text(l10n.settingsThemeLabel),
            value: Text(labState.themeLabel),
            onTap: () {
              onChanged(
                labState.copyWith(
                  themeLabel: labState.themeLabel == '深色' ? '浅色' : '深色',
                ),
              );
            },
          ),
          Md3eSettingsNavigationTile(
            leading: Symbols.language,
            title: Text(l10n.settingsLanguageLabel),
            value: Text(labState.localeLabel),
            onTap: () {
              onChanged(
                labState.copyWith(
                  localeLabel: labState.localeLabel == '简体中文'
                      ? 'English'
                      : '简体中文',
                ),
              );
            },
          ),
        ],
      ),
      Md3eSettingsSection(
        title: const Text('阅读相关偏好'),
        tiles: <Widget>[
          Md3eSettingsNavigationTile(
            leading: Symbols.menu_book,
            title: Text(l10n.readerSettingsReadingMode),
            value: Text(labState.readingModeLabel),
            onTap: () {
              onChanged(
                labState.copyWith(
                  readingModeLabel: _nextReadingModeLabel(
                    labState.readingModeLabel,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      Md3eSettingsSection(
        title: const Text('内容浏览'),
        tiles: <Widget>[
          Md3eSettingsSwitchTile(
            leading: Symbols.shield,
            title: const Text('Healthy mode'),
            description: const Text('库、搜索与历史中隐藏 R18 Comic，不修改分级'),
            value: labState.healthyMode,
            onChanged: (bool value) {
              onChanged(labState.copyWith(healthyMode: value));
            },
          ),
        ],
      ),
    ],
    Md3eSettingsCategory.metadataBackup => <Widget>[
      Md3eSettingsSection(
        title: Text(l10n.settingsMetadataBackupAutoGroupTitle),
        tiles: <Widget>[
          Md3eSettingsSwitchTile(
            leading: Symbols.backup,
            title: Text(l10n.settingsMetadataBackupAutoToggleLabel),
            description: Text(l10n.settingsMetadataBackupAutoToggleDescription),
            value: labState.autoMetadataBackup,
            onChanged: (bool value) {
              onChanged(labState.copyWith(autoMetadataBackup: value));
            },
          ),
        ],
      ),
      Md3eSettingsSection(
        title: Text(l10n.settingsMetadataBackupManualGroupTitle),
        tiles: <Widget>[
          Md3eSettingsNavigationTile(
            leading: Symbols.upload,
            title: Text(l10n.settingsMetadataBackupNowLabel),
            description: Text(l10n.settingsMetadataBackupNowDescription),
            onTap: () {},
          ),
          Md3eSettingsNavigationTile(
            leading: Symbols.folder_open,
            title: Text(l10n.settingsMetadataBackupOpenFolderLabel),
            description: Text(l10n.settingsMetadataBackupOpenFolderDescription),
            onTap: () {},
          ),
        ],
      ),
    ],
    Md3eSettingsCategory.diagnostics => <Widget>[
      Md3eSettingsSection(
        tiles: <Widget>[
          Md3eSettingsSwitchTile(
            leading: Symbols.bug_report,
            title: Text(l10n.settingsDiagnosticModeLabel),
            description: Text(
              labState.diagnosticMode
                  ? l10n.settingsDiagnosticModeDescriptionEnabled
                  : l10n.settingsDiagnosticModeDescriptionDisabled,
            ),
            value: labState.diagnosticMode,
            onChanged: (bool value) {
              onChanged(labState.copyWith(diagnosticMode: value));
            },
          ),
          Md3eSettingsNavigationTile(
            leading: Symbols.article,
            title: Text(l10n.settingsExportLogsLabel),
            onTap: () {},
          ),
        ],
      ),
    ],
    Md3eSettingsCategory.about => <Widget>[
      Md3eSettingsSection(
        tiles: <Widget>[
          Md3eSettingsSwitchTile(
            leading: Symbols.download,
            title: Text(l10n.settingsAutoUpdateLabel),
            value: labState.autoUpdate,
            onChanged: (bool value) {
              onChanged(labState.copyWith(autoUpdate: value));
            },
          ),
          Md3eSettingsNavigationTile(
            leading: Symbols.info,
            title: Text(l10n.settingsCheckForUpdatesLabel),
            value: Text(l10n.settingsCurrentVersion('0.0.0-lab')),
            onTap: () {},
          ),
        ],
      ),
    ],
  };
}

/// 阅读模式 preview 取值（与生产 `ReadingMode` 展示名对齐，循环切换）。
const List<String> kMd3eSettingsReadingModeLabels = <String>[
  '单页',
  '双页',
  '双页（封面独立）',
  'Webtoon',
];

String _nextReadingModeLabel(String current) {
  final int index = kMd3eSettingsReadingModeLabels.indexOf(current);
  return kMd3eSettingsReadingModeLabels[(index + 1) %
      kMd3eSettingsReadingModeLabels.length];
}

class Md3eSettingsLabState {
  const Md3eSettingsLabState({
    this.themeLabel = '深色',
    this.localeLabel = '简体中文',
    this.autoMetadataBackup = true,
    this.diagnosticMode = false,
    this.autoUpdate = true,
    this.readingModeLabel = '单页',
    this.healthyMode = false,
  });

  final String themeLabel;
  final String localeLabel;
  final bool autoMetadataBackup;
  final bool diagnosticMode;
  final bool autoUpdate;
  final String readingModeLabel;
  final bool healthyMode;

  Md3eSettingsLabState copyWith({
    String? themeLabel,
    String? localeLabel,
    bool? autoMetadataBackup,
    bool? diagnosticMode,
    bool? autoUpdate,
    String? readingModeLabel,
    bool? healthyMode,
  }) {
    return Md3eSettingsLabState(
      themeLabel: themeLabel ?? this.themeLabel,
      localeLabel: localeLabel ?? this.localeLabel,
      autoMetadataBackup: autoMetadataBackup ?? this.autoMetadataBackup,
      diagnosticMode: diagnosticMode ?? this.diagnosticMode,
      autoUpdate: autoUpdate ?? this.autoUpdate,
      readingModeLabel: readingModeLabel ?? this.readingModeLabel,
      healthyMode: healthyMode ?? this.healthyMode,
    );
  }
}
