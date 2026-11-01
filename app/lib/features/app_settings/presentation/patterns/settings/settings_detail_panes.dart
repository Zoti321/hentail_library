import 'package:flutter/material.dart';
import 'package:hentai_library/core/l10n/app_localizations.dart';
import 'package:hentai_library/core/l10n/app_localizations_x.dart';
import 'package:hentai_library/shared/ui/layout/settings_page_metrics.dart';
import 'package:hentai_library/features/app_settings/presentation/patterns/settings/metadata_backup_import_lab_flow.dart';
import 'package:hentai_library/features/app_settings/presentation/patterns/settings/settings_catalog.dart';
import 'package:hentai_library/shared/ui/widgets/settings/settings_list.dart';
import 'package:hentai_library/shared/ui/widgets/settings/settings_tile.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_symbols_icons/symbols.dart';

/// 生产或 Lab 注入某分类的 section 列表（每项为 [Md3eSettingsSection] 等组件）。
typedef Md3eSettingsSectionsBuilder = List<Widget> Function(
  BuildContext context,
  Md3eSettingsCategory category,
);

/// Detail pane for one [Md3eSettingsCategory].
///
/// 未提供 [sectionsBuilder] 时使用 Lab 的 mock 内容（[labState] 驱动）。
class Md3eSettingsDetailPane extends StatelessWidget {
  const Md3eSettingsDetailPane({
    super.key,
    required this.category,
    required this.showTitle,
    this.labState = const Md3eSettingsLabState(),
    this.onLabStateChanged,
    this.optionLabels = const Md3eSettingsOptionLabels(),
    this.showUnwiredTiles = true,
    this.sectionsBuilder,
  });

  final Md3eSettingsCategory category;
  final bool showTitle;
  final Md3eSettingsLabState labState;
  final ValueChanged<Md3eSettingsLabState>? onLabStateChanged;
  final Md3eSettingsOptionLabels optionLabels;
  final Md3eSettingsSectionsBuilder? sectionsBuilder;

  /// 为 false 时隐藏尚未接入业务的 tile（Pilot 页面使用）。
  final bool showUnwiredTiles;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final Md3eSettingsCategoryInfo info = kMd3eSettingsCategories.firstWhere(
      (Md3eSettingsCategoryInfo e) => e.category == category,
    );
    final List<Widget> sections =
        sectionsBuilder?.call(context, category) ??
        _sectionsForCategory(
          context,
          category,
          labState,
          onLabStateChanged ?? (Md3eSettingsLabState _) {},
          optionLabels,
          showUnwiredTiles,
        );
    final Widget body = Md3eSettingsList(
      maxWidth: Md3eSettingsPageMetrics.detailListMaxWidth,
      sections: sections,
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
  Md3eSettingsOptionLabels optionLabels,
  bool showUnwiredTiles,
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
                  themeLabel: nextMd3eOption(
                    labState.themeLabel,
                    optionLabels.themeOptions,
                  ),
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
                  localeLabel: nextMd3eOption(
                    labState.localeLabel,
                    optionLabels.localeOptions,
                  ),
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
                  readingModeLabel: nextMd3eOption(
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
          Md3eSettingsNavigationTile(
            leading: Symbols.restore,
            title: Text(l10n.settingsMetadataBackupImportLabel),
            description: Text(l10n.settingsMetadataBackupImportDescription),
            onTap: () => showMd3eMetadataBackupImportLabFlow(context),
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
          if (showUnwiredTiles)
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
          if (showUnwiredTiles)
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

/// 设置页可选项文案：Lab 使用默认值，生产 Pilot 注入 l10n 文案（顺序与枚举 `values` 一致）。
class Md3eSettingsOptionLabels {
  const Md3eSettingsOptionLabels({
    this.themeOptions = const <String>['深色', '浅色'],
    this.localeOptions = const <String>['简体中文', 'English'],
    this.readingModeOptions = kMd3eSettingsReadingModeLabels,
  });

  final List<String> themeOptions;
  final List<String> localeOptions;
  final List<String> readingModeOptions;
}

/// 循环切换到下一个可选项；当前值不在列表中时从第一项开始。
String nextMd3eOption(String current, List<String> options) {
  final int index = options.indexOf(current);
  return options[(index + 1) % options.length];
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
