import 'package:flutter/material.dart';
import 'package:hentai_library/l10n/app_localizations.dart';
import 'package:hentai_library/shared/ui/l10n/app_localizations_x.dart';
import 'package:hentai_library/design-system/design_system.dart';
import 'package:hentai_library/features/app_settings/presentation/patterns/settings/metadata_backup_import_lab_flow.dart';
import 'package:hentai_library/features/app_settings/presentation/patterns/settings/settings_catalog.dart';
import 'package:material_symbols_icons/symbols.dart';

/// 生产或 Lab 注入某分类的 section 列表（每项为 [SettingsSection] 等组件）。
typedef SettingsSectionsBuilder =
    List<Widget> Function(BuildContext context, SettingsCategory category);

/// Detail pane for one [SettingsCategory].
///
/// 未提供 [sectionsBuilder] 时使用 Lab mock（仅 reading / metadataBackup 有内容）。
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
        labMockSectionsForCategory(
          context,
          category,
          labState: labState,
          onLabStateChanged: onLabStateChanged ?? (SettingsLabState _) {},
          optionLabels: optionLabels,
          showUnwiredTiles: showUnwiredTiles,
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

/// In-memory Lab mocks for categories that are not yet faked via [settingsProvider].
List<Widget> labMockSectionsForCategory(
  BuildContext context,
  SettingsCategory category, {
  required SettingsLabState labState,
  required ValueChanged<SettingsLabState> onLabStateChanged,
  SettingsOptionLabels optionLabels = const SettingsOptionLabels(),
  bool showUnwiredTiles = true,
}) {
  final AppLocalizations l10n = context.l10n;
  final ValueChanged<SettingsLabState> onChanged = onLabStateChanged;
  return switch (category) {
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
    _ => const <Widget>[],
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

/// Lab mock option labels for reading / metadataBackup previews only.
class SettingsOptionLabels {
  const SettingsOptionLabels({
    this.readingModeOptions = kSettingsReadingModeLabels,
    this.autoPlayModeOptions = kSettingsAutoPlayModeLabels,
    this.pagedLayoutOptions = kSettingsPagedLayoutLabels,
    this.webtoonMarginOptions = kSettingsWebtoonMarginLabels,
    this.webtoonZoomOptions = kSettingsWebtoonZoomLabels,
  });

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

/// In-memory Lab state for categories that still use mock sections.
class SettingsLabState {
  const SettingsLabState({
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
