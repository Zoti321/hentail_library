import 'package:flutter/material.dart';
import 'package:hentai_library/core/l10n/app_localizations.dart';
import 'package:hentai_library/core/l10n/app_localizations_x.dart';
import 'package:hentai_library/shared/ui/layout/settings_page_metrics.dart';
import 'package:hentai_library/shared/ui/layout/spacing.dart';
import 'package:hentai_library/shared/ui/patterns/shared/page_title.dart';
import 'package:hentai_library/features/app_settings/presentation/patterns/settings/metadata_backup_import_lab_flow.dart';
import 'package:hentai_library/features/app_settings/presentation/patterns/settings/settings_catalog.dart';
import 'package:hentai_library/shared/ui/widgets/settings/settings_list.dart';
import 'package:hentai_library/shared/ui/widgets/settings/settings_tile.dart';
import 'package:material_symbols_icons/symbols.dart';

/// 生产或 Lab 注入某分类的 section 列表（每项为 [SettingsSection] 等组件）。
typedef SettingsSectionsBuilder = List<Widget> Function(
  BuildContext context,
  SettingsCategory category,
);

/// Detail pane for one [SettingsCategory].
///
/// 未提供 [sectionsBuilder] 时使用 Lab 的 mock 内容（[labState] 驱动）。
class SettingsDetailPane extends StatelessWidget {
  const SettingsDetailPane({
    super.key,
    required this.category,
    required this.showTitle,
    this.labState = const SettingsLabState(),
    this.onLabStateChanged,
    this.optionLabels = const SettingsOptionLabels(),
    this.showUnwiredTiles = true,
    this.sectionsBuilder,
  });

  final SettingsCategory category;
  final bool showTitle;
  final SettingsLabState labState;
  final ValueChanged<SettingsLabState>? onLabStateChanged;
  final SettingsOptionLabels optionLabels;
  final SettingsSectionsBuilder? sectionsBuilder;

  /// 为 false 时隐藏尚未接入业务的 tile（Pilot 页面使用）。
  final bool showUnwiredTiles;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final SettingsCategoryInfo info = kSettingsCategories.firstWhere(
      (SettingsCategoryInfo e) => e.category == category,
    );
    final List<Widget> sections =
        sectionsBuilder?.call(context, category) ??
        _sectionsForCategory(
          context,
          category,
          labState,
          onLabStateChanged ?? (SettingsLabState _) {},
          optionLabels,
          showUnwiredTiles,
        );
    final Widget body = SettingsList(
      maxWidth: SettingsPageMetrics.detailListMaxWidth,
      sections: sections,
    );

    if (!showTitle) {
      return body;
    }

    // 与页面标题同源字阶，左缘对齐页面留白（不再额外叠加水平内边距）。
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.only(bottom: Spacing.space8),
          child: PageTitle(info.label(l10n)),
        ),
        Expanded(child: body),
      ],
    );
  }
}

List<Widget> _sectionsForCategory(
  BuildContext context,
  SettingsCategory category,
  SettingsLabState labState,
  ValueChanged<SettingsLabState> onChanged,
  SettingsOptionLabels optionLabels,
  bool showUnwiredTiles,
) {
  final AppLocalizations l10n = context.l10n;
  return switch (category) {
    SettingsCategory.personalization => <Widget>[
      SettingsSection(
        title: Text(l10n.settingsSectionAppearance),
        tiles: <Widget>[
          SettingsNavigationTile(
            leading: Symbols.dark_mode,
            title: Text(l10n.settingsThemeLabel),
            value: Text(labState.themeLabel),
            onTap: () {
              onChanged(
                labState.copyWith(
                  themeLabel: nextOption(
                    labState.themeLabel,
                    optionLabels.themeOptions,
                  ),
                ),
              );
            },
          ),
          SettingsNavigationTile(
            leading: Symbols.language,
            title: Text(l10n.settingsLanguageLabel),
            value: Text(labState.localeLabel),
            onTap: () {
              onChanged(
                labState.copyWith(
                  localeLabel: nextOption(
                    labState.localeLabel,
                    optionLabels.localeOptions,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      SettingsSection(
        title: Text(l10n.settingsSectionReading),
        tiles: <Widget>[
          SettingsNavigationTile(
            leading: Symbols.menu_book,
            title: Text(l10n.readerSettingsReadingMode),
            value: Text(labState.readingModeLabel),
            onTap: () {
              onChanged(
                labState.copyWith(
                  readingModeLabel: nextOption(
                    labState.readingModeLabel,
                    optionLabels.readingModeOptions,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      if (showUnwiredTiles)
        SettingsSection(
          title: Text(l10n.settingsSectionLibraryBrowse),
          tiles: <Widget>[
            SettingsSwitchTile(
              leading: Symbols.shield,
              title: Text(l10n.settingsHealthyModeLabel),
              description: Text(l10n.settingsHealthyModeDescription),
              value: labState.healthyMode,
              onChanged: (bool value) {
                onChanged(labState.copyWith(healthyMode: value));
              },
            ),
          ],
        ),
    ],
    SettingsCategory.metadataBackup => <Widget>[
      SettingsSection(
        title: Text(l10n.settingsMetadataBackupAutoGroupTitle),
        tiles: <Widget>[
          SettingsSwitchTile(
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
      SettingsSection(
        title: Text(l10n.settingsMetadataBackupManualGroupTitle),
        tiles: <Widget>[
          SettingsNavigationTile(
            leading: Symbols.upload,
            title: Text(l10n.settingsMetadataBackupNowLabel),
            description: Text(l10n.settingsMetadataBackupNowDescription),
            onTap: () {},
          ),
          SettingsNavigationTile(
            leading: Symbols.folder_open,
            title: Text(l10n.settingsMetadataBackupOpenFolderLabel),
            description: Text(l10n.settingsMetadataBackupOpenFolderDescription),
            onTap: () {},
          ),
          SettingsNavigationTile(
            leading: Symbols.restore,
            title: Text(l10n.settingsMetadataBackupImportLabel),
            description: Text(l10n.settingsMetadataBackupImportDescription),
            onTap: () => showMetadataBackupImportLabFlow(context),
          ),
        ],
      ),
    ],
    SettingsCategory.diagnostics => <Widget>[
      SettingsSection(
        title: Text(l10n.settingsSectionDiagnostics),
        tiles: <Widget>[
          SettingsSwitchTile(
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
          if (showUnwiredTiles)
            SettingsNavigationTile(
              leading: Symbols.article,
              title: Text(l10n.settingsExportLogsLabel),
              onTap: () {},
            ),
        ],
      ),
    ],
    SettingsCategory.about => <Widget>[
      SettingsSection(
        title: Text(l10n.settingsSectionUpdates),
        tiles: <Widget>[
          SettingsSwitchTile(
            leading: Symbols.download,
            title: Text(l10n.settingsAutoUpdateLabel),
            value: labState.autoUpdate,
            onChanged: (bool value) {
              onChanged(labState.copyWith(autoUpdate: value));
            },
          ),
          if (showUnwiredTiles)
            SettingsNavigationTile(
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
const List<String> kSettingsReadingModeLabels = <String>[
  '单页',
  '双页',
  '双页（封面独立）',
  'Webtoon',
];

/// 设置页可选项文案：Lab 使用默认值，生产 Pilot 注入 l10n 文案（顺序与枚举 `values` 一致）。
class SettingsOptionLabels {
  const SettingsOptionLabels({
    this.themeOptions = const <String>['深色', '浅色'],
    this.localeOptions = const <String>['简体中文', 'English'],
    this.readingModeOptions = kSettingsReadingModeLabels,
  });

  final List<String> themeOptions;
  final List<String> localeOptions;
  final List<String> readingModeOptions;
}

/// 循环切换到下一个可选项；当前值不在列表中时从第一项开始。
String nextOption(String current, List<String> options) {
  final int index = options.indexOf(current);
  return options[(index + 1) % options.length];
}

class SettingsLabState {
  const SettingsLabState({
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

  SettingsLabState copyWith({
    String? themeLabel,
    String? localeLabel,
    bool? autoMetadataBackup,
    bool? diagnosticMode,
    bool? autoUpdate,
    String? readingModeLabel,
    bool? healthyMode,
  }) {
    return SettingsLabState(
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
