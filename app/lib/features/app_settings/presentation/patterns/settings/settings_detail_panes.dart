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
    final SettingsCategoryInfo info = settingsCategoryInfo(category);
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
    SettingsCategory.appearance => <Widget>[
      SettingsSection(
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
            leading: Symbols.text_fields,
            title: Text(l10n.settingsFontLabel),
            value: Text(labState.fontLabel),
            onTap: () {
              onChanged(
                labState.copyWith(
                  fontLabel: nextOption(
                    labState.fontLabel,
                    optionLabels.fontOptions,
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
    ],
    SettingsCategory.interface => <Widget>[
      SettingsSection(
        tiles: <Widget>[
          SettingsNavigationTile(
            leading: Symbols.tab,
            title: Text(l10n.settingsDefaultLibraryDisplayTargetLabel),
            description: Text(
              l10n.settingsDefaultLibraryDisplayTargetDescription,
            ),
            value: Text(labState.defaultLibraryDisplayTargetLabel),
            onTap: () {
              onChanged(
                labState.copyWith(
                  defaultLibraryDisplayTargetLabel: nextOption(
                    labState.defaultLibraryDisplayTargetLabel,
                    optionLabels.defaultLibraryDisplayTargetOptions,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    ],
    SettingsCategory.reading => <Widget>[
      SettingsSection(
        title: Text(l10n.readerSettingsReadingMode),
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
      SettingsSection(
        title: Text(l10n.readerSettingsAutoPlay),
        tiles: <Widget>[
          SettingsNavigationTile(
            leading: Symbols.repeat,
            title: Text(l10n.readerSettingsAutoPlayMode),
            value: Text(labState.autoPlayModeLabel),
            onTap: () {
              onChanged(
                labState.copyWith(
                  autoPlayModeLabel: nextOption(
                    labState.autoPlayModeLabel,
                    optionLabels.autoPlayModeOptions,
                  ),
                ),
              );
            },
          ),
          SettingsNavigationTile(
            leading: Symbols.timer,
            title: Text(l10n.readerSettingsPlayInterval),
            value: Text(
              '${labState.autoPlayIntervalSeconds} ${l10n.readerSettingsSecondsSuffix}',
            ),
            onTap: () {
              final int next = labState.autoPlayIntervalSeconds >= 10
                  ? 1
                  : labState.autoPlayIntervalSeconds + 1;
              onChanged(labState.copyWith(autoPlayIntervalSeconds: next));
            },
          ),
        ],
      ),
      SettingsSection(
        title: Text(l10n.readerSettingsPagedOptions),
        tiles: <Widget>[
          SettingsNavigationTile(
            leading: Symbols.view_day,
            title: Text(l10n.readerSettingsPageLayout),
            value: Text(labState.pagedLayoutLabel),
            onTap: () {
              onChanged(
                labState.copyWith(
                  pagedLayoutLabel: nextOption(
                    labState.pagedLayoutLabel,
                    optionLabels.pagedLayoutOptions,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      SettingsSection(
        title: Text(l10n.readerSettingsWebtoonMode),
        tiles: <Widget>[
          SettingsNavigationTile(
            leading: Symbols.width_normal,
            title: Text(l10n.readerSettingsHorizontalMargin),
            value: Text(labState.webtoonMarginLabel),
            onTap: () {
              onChanged(
                labState.copyWith(
                  webtoonMarginLabel: nextOption(
                    labState.webtoonMarginLabel,
                    optionLabels.webtoonMarginOptions,
                  ),
                ),
              );
            },
          ),
          SettingsNavigationTile(
            leading: Symbols.zoom_in,
            title: Text(l10n.readerSettingsZoomMode),
            value: Text(labState.webtoonZoomLabel),
            onTap: () {
              onChanged(
                labState.copyWith(
                  webtoonZoomLabel: nextOption(
                    labState.webtoonZoomLabel,
                    optionLabels.webtoonZoomOptions,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    ],
    SettingsCategory.libraryBrowse => <Widget>[
      if (showUnwiredTiles)
        SettingsSection(
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
    SettingsCategory.about => <Widget>[
      SettingsSection(
        tiles: <Widget>[
          SettingsNavigationTile(
            leading: Symbols.info,
            title: Text(l10n.settingsMetadataBackupImportManifestAppVersion),
            value: Text(l10n.settingsCurrentVersion('0.0.0-lab')),
          ),
        ],
      ),
    ],
    SettingsCategory.updates => <Widget>[
      SettingsSection(
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
              leading: Symbols.system_update,
              title: Text(l10n.settingsCheckForUpdatesLabel),
              value: Text(l10n.settingsCurrentVersion('0.0.0-lab')),
              onTap: () {},
            ),
        ],
      ),
    ],
    SettingsCategory.storageAndLogs => <Widget>[
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
  };
}

/// 阅读模式 preview 取值（与生产分类展示名对齐，循环切换）。
const List<String> kSettingsReadingModeLabels = <String>['翻页', 'Webtoon'];

/// 自动翻页范围 preview 取值。
const List<String> kSettingsAutoPlayModeLabels = <String>[
  '本话一次',
  '本话循环',
  '系列一次',
  '系列循环',
];

const List<String> kSettingsPagedLayoutLabels = <String>['单页', '双页'];

const List<String> kSettingsWebtoonMarginLabels = <String>[
  '无（0%）',
  '10%',
  '20%',
  '30%',
  '40%',
];

const List<String> kSettingsWebtoonZoomLabels = <String>['适应宽度', '原始尺寸'];

/// 设置页可选项文案：Lab 使用默认值，生产 Pilot 注入 l10n 文案（顺序与枚举 `values` 一致）。
class SettingsOptionLabels {
  const SettingsOptionLabels({
    this.themeOptions = const <String>['深色', '浅色'],
    this.localeOptions = const <String>['简体中文', 'English'],
    this.fontOptions = const <String>['小米字体', 'Noto Sans'],
    this.defaultLibraryDisplayTargetOptions = const <String>['漫画', '系列'],
    this.readingModeOptions = kSettingsReadingModeLabels,
    this.autoPlayModeOptions = kSettingsAutoPlayModeLabels,
    this.pagedLayoutOptions = kSettingsPagedLayoutLabels,
    this.webtoonMarginOptions = kSettingsWebtoonMarginLabels,
    this.webtoonZoomOptions = kSettingsWebtoonZoomLabels,
  });

  final List<String> themeOptions;
  final List<String> localeOptions;
  final List<String> fontOptions;
  final List<String> defaultLibraryDisplayTargetOptions;
  final List<String> readingModeOptions;
  final List<String> autoPlayModeOptions;
  final List<String> pagedLayoutOptions;
  final List<String> webtoonMarginOptions;
  final List<String> webtoonZoomOptions;
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
    this.fontLabel = '小米字体',
    this.defaultLibraryDisplayTargetLabel = '漫画',
    this.autoMetadataBackup = true,
    this.diagnosticMode = false,
    this.autoUpdate = true,
    this.readingModeLabel = '翻页',
    this.autoPlayModeLabel = '本话一次',
    this.autoPlayIntervalSeconds = 5,
    this.pagedLayoutLabel = '单页',
    this.webtoonMarginLabel = '20%',
    this.webtoonZoomLabel = '适应宽度',
    this.healthyMode = false,
  });

  final String themeLabel;
  final String localeLabel;
  final String fontLabel;
  final String defaultLibraryDisplayTargetLabel;
  final bool autoMetadataBackup;
  final bool diagnosticMode;
  final bool autoUpdate;
  final String readingModeLabel;
  final String autoPlayModeLabel;
  final int autoPlayIntervalSeconds;
  final String pagedLayoutLabel;
  final String webtoonMarginLabel;
  final String webtoonZoomLabel;
  final bool healthyMode;

  SettingsLabState copyWith({
    String? themeLabel,
    String? localeLabel,
    String? fontLabel,
    String? defaultLibraryDisplayTargetLabel,
    bool? autoMetadataBackup,
    bool? diagnosticMode,
    bool? autoUpdate,
    String? readingModeLabel,
    String? autoPlayModeLabel,
    int? autoPlayIntervalSeconds,
    String? pagedLayoutLabel,
    String? webtoonMarginLabel,
    String? webtoonZoomLabel,
    bool? healthyMode,
  }) {
    return SettingsLabState(
      themeLabel: themeLabel ?? this.themeLabel,
      localeLabel: localeLabel ?? this.localeLabel,
      fontLabel: fontLabel ?? this.fontLabel,
      defaultLibraryDisplayTargetLabel:
          defaultLibraryDisplayTargetLabel ??
          this.defaultLibraryDisplayTargetLabel,
      autoMetadataBackup: autoMetadataBackup ?? this.autoMetadataBackup,
      diagnosticMode: diagnosticMode ?? this.diagnosticMode,
      autoUpdate: autoUpdate ?? this.autoUpdate,
      readingModeLabel: readingModeLabel ?? this.readingModeLabel,
      autoPlayModeLabel: autoPlayModeLabel ?? this.autoPlayModeLabel,
      autoPlayIntervalSeconds:
          autoPlayIntervalSeconds ?? this.autoPlayIntervalSeconds,
      pagedLayoutLabel: pagedLayoutLabel ?? this.pagedLayoutLabel,
      webtoonMarginLabel: webtoonMarginLabel ?? this.webtoonMarginLabel,
      webtoonZoomLabel: webtoonZoomLabel ?? this.webtoonZoomLabel,
      healthyMode: healthyMode ?? this.healthyMode,
    );
  }
}
