import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/core/l10n/app_localizations.dart';
import 'package:hentai_library/core/l10n/app_localizations_x.dart';
import 'package:hentai_library/features/app_settings/presentation/app_data_wipe_flow.dart';
import 'package:hentai_library/features/app_settings/presentation/log_export_flow.dart';
import 'package:hentai_library/features/app_settings/presentation/view_models/app_update_controller.dart';
import 'package:hentai_library/features/app_settings/presentation/view_models/diagnostic_mode_notifier.dart';
import 'package:hentai_library/features/app_settings/presentation/view_models/settings_notifier.dart';
import 'package:hentai_library/features/app_settings/presentation/patterns/settings/settings_catalog.dart';
import 'package:hentai_library/features/app_settings/presentation/views/dialogs/color_scheme_picker_dialog.dart';
import 'package:hentai_library/shared/ui/widgets/menu/anchored_menu.dart';
import 'package:hentai_library/shared/ui/widgets/settings/settings_list.dart';
import 'package:hentai_library/shared/ui/widgets/settings/settings_tile.dart';
import 'package:hentai_library/shared/di/library_state_providers.dart';
import 'package:hentai_library/shared/di/settings_slot_providers.dart';
import 'package:hentai_library/features/app_settings/domain/app_setting.dart';
import 'package:hentai_library/features/app_settings/domain/reader_session_preference_types.dart';
import 'package:hentai_library/features/comic/public/smart_facet_match_preference.dart';
import 'package:hentai_library/features/read_session/public/reading_preference_l10n.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// 生产设置页某分类的 MD3E section 列表。
///
/// 状态由各 tile（ConsumerWidget）自行 watch，section 本身无状态。
/// 选项循环使用枚举 `values`，不经过字符串 label 反查。
List<Widget> settingsSectionsFor(
  SettingsCategory category,
  BuildContext context,
) {
  final AppLocalizations l10n = context.l10n;
  return switch (category) {
    SettingsCategory.appearance => _appearanceSections(),
    SettingsCategory.interface => _interfaceSections(),
    SettingsCategory.reading => const <Widget>[_ReadingSettingsCategory()],
    SettingsCategory.libraryBrowse => _libraryBrowseSections(),
    SettingsCategory.metadataBackup => const <Widget>[
      _MetadataBackupCategory(),
    ],
    SettingsCategory.about => const <Widget>[_AboutVersionSection()],
    SettingsCategory.updates => _updatesSections(),
    SettingsCategory.storageAndLogs => _storageAndLogsSections(l10n),
  };
}

/// 弹出 M3E 选择菜单（锚定在触发行上），选中项回传给 [onSelected]。
Future<void> _pickSettingOption<T extends Object>(
  BuildContext context, {
  required List<T> options,
  required T selected,
  required String Function(T option) labelOf,
  required ValueChanged<T> onSelected,
}) async {
  final Rect? anchor = menuAnchorRectFor(context);
  if (anchor == null) {
    return;
  }
  final Object? picked = await showAnchoredMenu<Object>(
    context: context,
    anchor: anchor,
    children: <M3EMenuNode>[
      for (final T option in options)
        M3EMenuSelectable(
          label: labelOf(option),
          value: option,
          selected: option == selected,
        ),
    ],
  );
  if (picked is T) {
    onSelected(picked);
  }
}

List<Widget> _appearanceSections() {
  return const <Widget>[
    SettingsSection(
      tiles: <Widget>[
        _ThemeTile(),
        _DynamicColorTile(),
        _ColorSchemeTile(),
      ],
    ),
  ];
}

List<Widget> _interfaceSections() {
  return const <Widget>[
    SettingsSection(
      tiles: <Widget>[
        _FontTile(),
        _LocaleTile(),
      ],
    ),
  ];
}

/// 条漫边距可选值（百分比），与阅读页设置面板对齐，步长 5。
final List<int> _kWebtoonMarginOptions = List<int>.generate(
  9,
  (int i) => i * 5,
);

List<Widget> _libraryBrowseSections() {
  return const <Widget>[
    SettingsSection(
      tiles: <Widget>[
        _SmartFacetMatchTile(),
        _HealthyModeTile(),
        _PreferLibraryRootSeriesTile(),
      ],
    ),
  ];
}

List<Widget> _storageAndLogsSections(AppLocalizations l10n) {
  return <Widget>[
    SettingsSection(
      title: Text(l10n.settingsSectionDiagnostics),
      tiles: const <Widget>[_DiagnosticModeTile(), _ExportLogsTile()],
    ),
    SettingsSection(
      title: Text(l10n.settingsSectionApplicationData),
      tiles: const <Widget>[
        _ClearApplicationDataTile(),
        _UninstallDataInfoTile(),
      ],
    ),
  ];
}

List<Widget> _updatesSections() {
  return const <Widget>[
    SettingsSection(
      tiles: <Widget>[_AutoUpdateTile(), _CheckUpdateTile()],
    ),
  ];
}

class _AboutVersionSection extends ConsumerWidget {
  const _AboutVersionSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = context.l10n;
    final AsyncValue<PackageInfo> packageInfoAsync = ref.watch(
      packageInfoProvider,
    );
    final String versionLabel = packageInfoAsync.maybeWhen(
      data: (PackageInfo info) => l10n.settingsCurrentVersion(info.version),
      orElse: () => l10n.settingsCurrentVersionLoading,
    );
    return SettingsSection(
      tiles: <Widget>[
        SettingsNavigationTile(
          leading: Symbols.info,
          title: Text(l10n.settingsMetadataBackupImportManifestAppVersion),
          value: Text(versionLabel),
        ),
      ],
    );
  }
}

class _ThemeTile extends ConsumerWidget {
  const _ThemeTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = context.l10n;
    final AppThemePreference preference = ref.watch(
      settingsProvider.select(
        (AsyncValue<AppSetting> async) =>
            async.asData?.value.themePreference ?? AppThemePreference.system,
      ),
    );
    return SettingsNavigationTile(
      leading: Symbols.dark_mode,
      title: Text(l10n.settingsThemeLabel),
      value: Text(l10n.themePreferenceLabel(preference)),
      onTap: () => _pickSettingOption<AppThemePreference>(
        context,
        options: AppThemePreference.values,
        selected: preference,
        labelOf: l10n.themePreferenceLabel,
        onSelected: ref.read(settingsProvider.notifier).setThemePreference,
      ),
    );
  }
}

class _DynamicColorTile extends ConsumerWidget {
  const _DynamicColorTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = context.l10n;
    final bool enabled = ref.watch(
      settingsProvider.select(
        (AsyncValue<AppSetting> async) =>
            async.asData?.value.useDynamicColor ?? false,
      ),
    );
    return SettingsSwitchTile(
      leading: Symbols.wallpaper,
      title: Text(l10n.settingsDynamicColorLabel),
      description: Text(l10n.settingsDynamicColorDescription),
      value: enabled,
      onChanged: (bool value) =>
          ref.read(settingsProvider.notifier).setUseDynamicColor(value),
    );
  }
}

class _ColorSchemeTile extends ConsumerWidget {
  const _ColorSchemeTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = context.l10n;
    final ({AppColorSchemePreference preference, bool useDynamicColor}) state =
        ref.watch(
          settingsProvider.select((AsyncValue<AppSetting> async) {
            final AppSetting? setting = async.asData?.value;
            return (
              preference:
                  setting?.colorSchemePreference ??
                  AppColorSchemePreference.brand,
              useDynamicColor: setting?.useDynamicColor ?? false,
            );
          }),
        );
    return SettingsNavigationTile(
      leading: Symbols.palette,
      title: Text(l10n.settingsColorSchemeLabel),
      value: Text(l10n.colorSchemePreferenceLabel(state.preference)),
      enabled: !state.useDynamicColor,
      onTap: () async {
        final AppColorSchemePreference? picked =
            await showColorSchemePickerDialog(
              context: context,
              selected: state.preference,
            );
        if (picked == null || picked == state.preference) {
          return;
        }
        await ref
            .read(settingsProvider.notifier)
            .setColorSchemePreference(picked);
      },
    );
  }
}

class _FontTile extends ConsumerWidget {
  const _FontTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = context.l10n;
    final AppFontPreference preference = ref.watch(
      settingsProvider.select(
        (AsyncValue<AppSetting> async) =>
            async.asData?.value.fontPreference ?? AppFontPreference.miSans,
      ),
    );
    return SettingsNavigationTile(
      leading: Symbols.text_fields,
      title: Text(l10n.settingsFontLabel),
      value: Text(l10n.fontPreferenceLabel(preference)),
      onTap: () => _pickSettingOption<AppFontPreference>(
        context,
        options: AppFontPreference.values,
        selected: preference,
        labelOf: l10n.fontPreferenceLabel,
        onSelected: ref.read(settingsProvider.notifier).setFontPreference,
      ),
    );
  }
}

class _LocaleTile extends ConsumerWidget {
  const _LocaleTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = context.l10n;
    final AppLocalePreference preference = ref.watch(
      settingsProvider.select(
        (AsyncValue<AppSetting> async) =>
            async.asData?.value.localePreference ?? AppLocalePreference.system,
      ),
    );
    return SettingsNavigationTile(
      leading: Symbols.language,
      title: Text(l10n.settingsLanguageLabel),
      value: Text(l10n.localePreferenceLabel(preference)),
      onTap: () => _pickSettingOption<AppLocalePreference>(
        context,
        options: AppLocalePreference.values,
        selected: preference,
        labelOf: l10n.localePreferenceLabel,
        onSelected: ref.read(settingsProvider.notifier).setLocalePreference,
      ),
    );
  }
}

/// 设置 → 阅读设置：与阅读页 [ReaderSettingsSheet] 可配置项对齐。
class _ReadingSettingsCategory extends ConsumerWidget {
  const _ReadingSettingsCategory();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = context.l10n;
    final AppSetting? settings = ref.watch(settingsProvider).asData?.value;
    if (settings == null) {
      return const SizedBox(
        height: 120,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    final SettingsNotifier notifier = ref.read(settingsProvider.notifier);
    final ReadingMode mode = settings.readingMode;
    final ReaderModeCategory category = mode.category;
    final PagedLayout pagedLayout = mode.pagedLayout ?? PagedLayout.single;
    final bool isWebtoon = mode.isWebtoon;
    final int interval = settings.readerAutoPlayIntervalSeconds;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        SettingsSection(
          title: Text(l10n.readerSettingsReadingMode),
          tiles: <Widget>[
            SettingsNavigationTile(
              leading: Symbols.menu_book,
              title: Text(l10n.readerSettingsReadingMode),
              value: Text(l10n.readerModeCategoryLabel(category)),
              onTap: () => _pickSettingOption<ReaderModeCategory>(
                context,
                options: ReaderModeCategory.values,
                selected: category,
                labelOf: l10n.readerModeCategoryLabel,
                onSelected: (ReaderModeCategory value) {
                  notifier.setReadingMode(switch (value) {
                    ReaderModeCategory.paged => pagedLayout.toReadingMode(),
                    ReaderModeCategory.webtoon => ReadingMode.webtoon,
                  });
                },
              ),
            ),
          ],
        ),
        if (!isWebtoon)
          SettingsSection(
            title: Text(l10n.readerSettingsPagedOptions),
            tiles: <Widget>[
              SettingsNavigationTile(
                leading: Symbols.view_day,
                title: Text(l10n.readerSettingsPageLayout),
                value: Text(l10n.pagedLayoutLabel(pagedLayout)),
                onTap: () => _pickSettingOption<PagedLayout>(
                  context,
                  options: PagedLayout.values,
                  selected: pagedLayout,
                  labelOf: l10n.pagedLayoutLabel,
                  onSelected: (PagedLayout value) {
                    notifier.setReadingMode(value.toReadingMode());
                  },
                ),
              ),
            ],
          ),
        if (isWebtoon)
          SettingsSection(
            title: Text(l10n.readerSettingsWebtoonMode),
            tiles: <Widget>[
              SettingsNavigationTile(
                leading: Symbols.width_normal,
                title: Text(l10n.readerSettingsHorizontalMargin),
                enabled: settings.webtoonZoomMode == WebtoonZoomMode.fitWidth,
                value: Text(
                  l10n.readerWebtoonMarginLabel(settings.webtoonMarginPercent),
                ),
                onTap: () => _pickSettingOption<int>(
                  context,
                  options: _kWebtoonMarginOptions,
                  selected: settings.webtoonMarginPercent,
                  labelOf: l10n.readerWebtoonMarginLabel,
                  onSelected: notifier.setWebtoonMarginPercent,
                ),
              ),
              SettingsNavigationTile(
                leading: Symbols.zoom_in,
                title: Text(l10n.readerSettingsZoomMode),
                value: Text(
                  l10n.webtoonZoomModeLabel(settings.webtoonZoomMode),
                ),
                onTap: () => _pickSettingOption<WebtoonZoomMode>(
                  context,
                  options: WebtoonZoomMode.values,
                  selected: settings.webtoonZoomMode,
                  labelOf: l10n.webtoonZoomModeLabel,
                  onSelected: notifier.setWebtoonZoomMode,
                ),
              ),
            ],
          ),
        SettingsSection(
          title: Text(l10n.readerSettingsAutoPlay),
          tiles: <Widget>[
            SettingsNavigationTile(
              leading: Symbols.repeat,
              title: Text(l10n.readerSettingsAutoPlayMode),
              value: Text(l10n.autoPlayModeLabel(settings.autoPlayMode)),
              onTap: () => _pickSettingOption<AutoPlayMode>(
                context,
                options: AutoPlayMode.values,
                selected: settings.autoPlayMode,
                labelOf: l10n.autoPlayModeLabel,
                onSelected: notifier.setAutoPlayMode,
              ),
            ),
            SettingsNavigationTile(
              leading: Symbols.timer,
              title: Text(l10n.readerSettingsPlayInterval),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  IconButton(
                    icon: const Icon(Symbols.remove),
                    onPressed: interval <= kReaderAutoPlayIntervalMin
                        ? null
                        : () => notifier.setReaderAutoPlayIntervalSeconds(
                            clampReaderAutoPlayInterval(interval - 1),
                          ),
                  ),
                  Text('$interval ${l10n.readerSettingsSecondsSuffix}'),
                  IconButton(
                    icon: const Icon(Symbols.add),
                    onPressed: interval >= kReaderAutoPlayIntervalMax
                        ? null
                        : () => notifier.setReaderAutoPlayIntervalSeconds(
                            clampReaderAutoPlayInterval(interval + 1),
                          ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _SmartFacetMatchTile extends ConsumerWidget {
  const _SmartFacetMatchTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = context.l10n;
    final AsyncValue<bool> preference = ref.watch(
      smartFacetMatchPreferenceProvider,
    );
    final bool enabled = preference.value ?? true;
    return SettingsSwitchTile(
      leading: Symbols.auto_awesome,
      title: Text(l10n.smartFacetMatchToggleLabel),
      value: enabled,
      enabled: !preference.isLoading,
      onChanged: (bool value) => ref
          .read(smartFacetMatchPreferenceProvider.notifier)
          .setEnabled(value),
    );
  }
}

class _HealthyModeTile extends ConsumerWidget {
  const _HealthyModeTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = context.l10n;
    final bool enabled = ref.watch(
      settingsProvider.select(
        (AsyncValue<AppSetting> async) =>
            async.asData?.value.healthyMode ?? false,
      ),
    );
    return SettingsSwitchTile(
      leading: Symbols.shield,
      title: Text(l10n.settingsHealthyModeLabel),
      description: Text(l10n.settingsHealthyModeDescription),
      value: enabled,
      onChanged: (bool value) =>
          ref.read(settingsProvider.notifier).setHealthyMode(value),
    );
  }
}

class _PreferLibraryRootSeriesTile extends ConsumerWidget {
  const _PreferLibraryRootSeriesTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = context.l10n;
    final bool enabled = ref.watch(
      settingsProvider.select(
        (AsyncValue<AppSetting> async) =>
            async.asData?.value.preferLibraryRootSeries ?? true,
      ),
    );
    return SettingsSwitchTile(
      leading: Symbols.low_priority,
      title: Text(l10n.settingsPreferLibraryRootSeriesLabel),
      description: Text(l10n.settingsPreferLibraryRootSeriesDescription),
      value: enabled,
      onChanged: (bool value) =>
          ref.read(settingsProvider.notifier).setPreferLibraryRootSeries(value),
    );
  }
}

class _DiagnosticModeTile extends ConsumerWidget {
  const _DiagnosticModeTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = context.l10n;
    final bool enabled = ref.watch(diagnosticModeProvider);
    return SettingsSwitchTile(
      leading: Symbols.bug_report,
      title: Text(l10n.settingsDiagnosticModeLabel),
      description: Text(
        enabled
            ? l10n.settingsDiagnosticModeDescriptionEnabled
            : l10n.settingsDiagnosticModeDescriptionDisabled,
      ),
      value: enabled,
      onChanged: (bool value) =>
          ref.read(diagnosticModeProvider.notifier).setEnabled(value),
    );
  }
}

class _ExportLogsTile extends ConsumerWidget {
  const _ExportLogsTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = context.l10n;
    return SettingsNavigationTile(
      leading: Symbols.article,
      title: Text(l10n.settingsExportLogsLabel),
      description: Text(l10n.settingsExportLogsDescription),
      onTap: () => runLogExportFlow(
        context,
        diagnosticVerbose: ref.read(diagnosticModeProvider),
      ),
    );
  }
}

class _ClearApplicationDataTile extends ConsumerWidget {
  const _ClearApplicationDataTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = context.l10n;
    final bool syncRunning = ref.watch(libraryScanRunningStateProvider);
    return SettingsNavigationTile(
      leading: Symbols.delete_forever,
      title: Text(l10n.settingsClearApplicationDataLabel),
      description: Text(
        syncRunning
            ? l10n.settingsClearApplicationDataDisabledSyncRunning
            : l10n.settingsClearApplicationDataDescription,
      ),
      enabled: !syncRunning,
      onTap: () => runAppDataWipeFlow(
        context,
        readRecentMetadataBackupAt: ref.read(
          recentMetadataBackupAtReaderProvider,
        ),
      ),
    );
  }
}

class _UninstallDataInfoTile extends StatelessWidget {
  const _UninstallDataInfoTile();

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    return SettingsNavigationTile(
      leading: Symbols.info,
      title: Text(l10n.settingsUninstallDataInfoLabel),
      description: Text(l10n.settingsUninstallDataInfoDescription),
    );
  }
}

class _AutoUpdateTile extends ConsumerWidget {
  const _AutoUpdateTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = context.l10n;
    final bool autoUpdate = ref.watch(
      settingsProvider.select(
        (AsyncValue<AppSetting> async) =>
            async.asData?.value.autoUpdate ?? true,
      ),
    );
    return SettingsSwitchTile(
      leading: Symbols.download,
      title: Text(l10n.settingsAutoUpdateLabel),
      value: autoUpdate,
      onChanged: (bool value) =>
          ref.read(settingsProvider.notifier).setAutoUpdate(value),
    );
  }
}

class _CheckUpdateTile extends ConsumerWidget {
  const _CheckUpdateTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = context.l10n;
    final AsyncValue<PackageInfo> packageInfoAsync = ref.watch(
      packageInfoProvider,
    );
    final String versionLabel = packageInfoAsync.maybeWhen(
      data: (PackageInfo info) => l10n.settingsCurrentVersion(info.version),
      orElse: () => l10n.settingsCurrentVersionLoading,
    );
    return SettingsNavigationTile(
      leading: Symbols.info,
      title: Text(l10n.settingsCheckForUpdatesLabel),
      value: Text(versionLabel),
      onTap: packageInfoAsync.isLoading
          ? null
          : () => ref
                .read(appUpdateControllerProvider.notifier)
                .runManualCheck(context: context),
    );
  }
}

/// 元数据备份分类：内容由 metadata_backup 通过槽位提供。
class _MetadataBackupCategory extends ConsumerWidget {
  const _MetadataBackupCategory();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref.watch(metadataBackupSettingsSectionBuilderProvider)(context);
  }
}
