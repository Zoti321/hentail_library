import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/core/l10n/app_localizations.dart';
import 'package:hentai_library/core/l10n/app_localizations_x.dart';
import 'package:hentai_library/features/app_settings/presentation/log_export_flow.dart';
import 'package:hentai_library/features/app_settings/presentation/view_models/app_update_controller.dart';
import 'package:hentai_library/features/app_settings/presentation/view_models/diagnostic_mode_notifier.dart';
import 'package:hentai_library/features/app_settings/presentation/view_models/settings_notifier.dart';
import 'package:hentai_library/features/app_settings/presentation/patterns/settings/settings_catalog.dart';
import 'package:hentai_library/features/app_settings/presentation/views/dialogs/color_scheme_picker_dialog.dart';
import 'package:hentai_library/design-system/components/menu/anchored_menu.dart';
import 'package:hentai_library/shared/ui/widgets/settings/settings_list.dart';
import 'package:hentai_library/shared/ui/widgets/settings/settings_tile.dart';
import 'package:hentai_library/shared/ui/l10n/library_display_target_l10n.dart';
import 'package:hentai_library/features/app_settings/domain/app_setting.dart';
import 'package:hentai_library/shared/domain/models/enums.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:hentai_library/features/app_settings/public/ui/l10n/app_settings_l10n.dart';

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
    SettingsCategory.reading => const <Widget>[],
    SettingsCategory.libraryBrowse => _libraryBrowseSections(),
    // 「元数据备份」分区由 metadata_backup 提供，组合根经 sectionsBuilder 注入。
    SettingsCategory.metadataBackup => const <Widget>[],
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
        _ColorSchemeTile(),
        _DynamicColorTile(),
        _FontTile(),
        _LocaleTile(),
      ],
    ),
  ];
}

List<Widget> _interfaceSections() {
  return const <Widget>[
    SettingsSection(tiles: <Widget>[_DefaultLibraryDisplayTargetTile()]),
  ];
}

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
  ];
}

List<Widget> _updatesSections() {
  return const <Widget>[
    SettingsSection(tiles: <Widget>[_AutoUpdateTile(), _CheckUpdateTile()]),
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

class _DefaultLibraryDisplayTargetTile extends ConsumerWidget {
  const _DefaultLibraryDisplayTargetTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = context.l10n;
    final LibraryDisplayTarget preference = ref.watch(
      settingsProvider.select(
        (AsyncValue<AppSetting> async) =>
            async.asData?.value.defaultLibraryDisplayTarget ??
            LibraryDisplayTarget.comics,
      ),
    );
    return SettingsNavigationTile(
      leading: Symbols.tab,
      title: Text(l10n.settingsDefaultLibraryDisplayTargetLabel),
      description: Text(l10n.settingsDefaultLibraryDisplayTargetDescription),
      value: Text(l10n.libraryDisplayTargetTabLabel(preference)),
      onTap: () => _pickSettingOption<LibraryDisplayTarget>(
        context,
        options: LibraryDisplayTarget.values,
        selected: preference,
        labelOf: l10n.libraryDisplayTargetTabLabel,
        onSelected: ref
            .read(settingsProvider.notifier)
            .setDefaultLibraryDisplayTarget,
      ),
    );
  }
}

class _SmartFacetMatchTile extends ConsumerWidget {
  const _SmartFacetMatchTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = context.l10n;
    final bool enabled = ref.watch(
      settingsProvider.select(
        (AsyncValue<AppSetting> async) =>
            async.asData?.value.smartFacetMatchEnabled ?? true,
      ),
    );
    return SettingsSwitchTile(
      leading: Symbols.auto_awesome,
      title: Text(l10n.smartFacetMatchToggleLabel),
      value: enabled,
      onChanged: (bool value) =>
          ref.read(settingsProvider.notifier).setSmartFacetMatchEnabled(value),
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
