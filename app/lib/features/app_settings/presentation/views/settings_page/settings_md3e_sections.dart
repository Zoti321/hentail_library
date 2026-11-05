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
import 'package:hentai_library/shared/ui/widgets/menu/anchored_menu.dart';
import 'package:hentai_library/shared/ui/widgets/settings/settings_list.dart';
import 'package:hentai_library/shared/ui/widgets/settings/settings_tile.dart';
import 'package:hentai_library/shared/di/library_state_providers.dart';
import 'package:hentai_library/shared/di/settings_slot_providers.dart';
import 'package:hentai_library/features/app_settings/domain/app_setting.dart';
import 'package:hentai_library/features/app_settings/presentation/patterns/settings/reading_mode_l10n.dart';
import 'package:hentai_library/features/app_settings/domain/reader_session_preference_types.dart';
import 'package:hentai_library/features/comic/public/smart_facet_match_preference.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// 生产设置页某分类的 MD3E section 列表。
///
/// 状态由各 tile（ConsumerWidget）自行 watch，section 本身无状态。
/// 选项循环使用枚举 `values`，不经过字符串 label 反查。
List<Widget> settingsMd3eSectionsFor(
  Md3eSettingsCategory category,
  BuildContext context,
) {
  final AppLocalizations l10n = context.l10n;
  return switch (category) {
    Md3eSettingsCategory.personalization => _personalizationSections(l10n),
    Md3eSettingsCategory.metadataBackup => const <Widget>[
      _MetadataBackupCategory(),
    ],
    Md3eSettingsCategory.diagnostics => _diagnosticsSections(l10n),
    Md3eSettingsCategory.about => _aboutSections(l10n),
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
  final Rect? anchor = md3eMenuAnchorRectFor(context);
  if (anchor == null) {
    return;
  }
  final Object? picked = await md3eShowAnchoredMenu<Object>(
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

List<Widget> _personalizationSections(AppLocalizations l10n) {
  return <Widget>[
    Md3eSettingsSection(
      title: Text(l10n.settingsSectionAppearance),
      tiles: const <Widget>[_ThemeTile(), _LocaleTile()],
    ),
    Md3eSettingsSection(
      title: Text(l10n.settingsSectionReading),
      tiles: const <Widget>[_ReadingModeTile()],
    ),
    Md3eSettingsSection(
      title: Text(l10n.settingsSectionLibraryBrowse),
      tiles: const <Widget>[
        _SmartFacetMatchTile(),
        _HealthyModeTile(),
        _PreferLibraryRootSeriesTile(),
      ],
    ),
  ];
}

List<Widget> _diagnosticsSections(AppLocalizations l10n) {
  return <Widget>[
    Md3eSettingsSection(
      title: Text(l10n.settingsSectionDiagnostics),
      tiles: const <Widget>[_DiagnosticModeTile(), _ExportLogsTile()],
    ),
    Md3eSettingsSection(
      title: Text(l10n.settingsSectionApplicationData),
      tiles: const <Widget>[
        _ClearApplicationDataTile(),
        _UninstallDataInfoTile(),
      ],
    ),
  ];
}

List<Widget> _aboutSections(AppLocalizations l10n) {
  return <Widget>[
    Md3eSettingsSection(
      title: Text(l10n.settingsSectionUpdates),
      tiles: const <Widget>[_AutoUpdateTile(), _CheckUpdateTile()],
    ),
  ];
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
    return Md3eSettingsNavigationTile(
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
    return Md3eSettingsNavigationTile(
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

class _ReadingModeTile extends ConsumerWidget {
  const _ReadingModeTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = context.l10n;
    final ReadingMode mode = ref.watch(
      settingsProvider.select(
        (AsyncValue<AppSetting> async) =>
            async.asData?.value.readingMode ?? kDefaultReadingMode,
      ),
    );
    return Md3eSettingsNavigationTile(
      leading: Symbols.menu_book,
      title: Text(l10n.readerSettingsReadingMode),
      value: Text(l10n.readingModeLabel(mode)),
      onTap: () => _pickSettingOption<ReadingMode>(
        context,
        options: ReadingMode.values,
        selected: mode,
        labelOf: l10n.readingModeLabel,
        onSelected: ref.read(settingsProvider.notifier).setReadingMode,
      ),
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
    return Md3eSettingsSwitchTile(
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
    return Md3eSettingsSwitchTile(
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
    return Md3eSettingsSwitchTile(
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
    return Md3eSettingsSwitchTile(
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
    return Md3eSettingsNavigationTile(
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
    return Md3eSettingsNavigationTile(
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
    return Md3eSettingsNavigationTile(
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
    return Md3eSettingsSwitchTile(
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
    return Md3eSettingsNavigationTile(
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
