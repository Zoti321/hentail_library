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
import 'package:hentai_library/shared/ui/widgets/settings/settings_list.dart';
import 'package:hentai_library/shared/ui/widgets/settings/settings_tile.dart';
import 'package:hentai_library/shared/di/library_state_providers.dart';
import 'package:hentai_library/shared/di/settings_slot_providers.dart';
import 'package:hentai_library/shared/domain/models/app_setting.dart';
import 'package:hentai_library/shared/domain/reading/reading_mode.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// 生产设置页某分类的 MD3E section 列表。
///
/// 状态由各 tile（ConsumerWidget）自行 watch，section 本身无状态。
/// 选项循环使用枚举 `values`，不经过字符串 label 反查。
List<Widget> settingsMd3eSectionsFor(Md3eSettingsCategory category) {
  return switch (category) {
    Md3eSettingsCategory.personalization => _personalizationSections(),
    Md3eSettingsCategory.metadataBackup => const <Widget>[
      _MetadataBackupCategory(),
    ],
    Md3eSettingsCategory.diagnostics => _diagnosticsSections(),
    Md3eSettingsCategory.about => _aboutSections(),
  };
}

/// 枚举循环：返回 [values] 中 [current] 之后的下一项（末尾回到首项）。
T _nextEnumValue<T>(List<T> values, T current) {
  return values[(values.indexOf(current) + 1) % values.length];
}

List<Widget> _personalizationSections() {
  return const <Widget>[
    Md3eSettingsSection(
      tiles: <Widget>[_ThemeTile(), _LocaleTile(), _ReadingModeTile()],
    ),
    Md3eSettingsSection(tiles: <Widget>[_HealthyModeTile()]),
  ];
}

List<Widget> _diagnosticsSections() {
  return const <Widget>[
    Md3eSettingsSection(
      tiles: <Widget>[
        _DiagnosticModeTile(),
        _ExportLogsTile(),
        _ClearApplicationDataTile(),
        _UninstallDataInfoTile(),
      ],
    ),
  ];
}

List<Widget> _aboutSections() {
  return const <Widget>[
    Md3eSettingsSection(tiles: <Widget>[_AutoUpdateTile(), _CheckUpdateTile()]),
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
      onTap: () => ref
          .read(settingsProvider.notifier)
          .setThemePreference(
            _nextEnumValue(AppThemePreference.values, preference),
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
      onTap: () => ref
          .read(settingsProvider.notifier)
          .setLocalePreference(
            _nextEnumValue(AppLocalePreference.values, preference),
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
      onTap: () => ref
          .read(settingsProvider.notifier)
          .setReadingMode(_nextEnumValue(ReadingMode.values, mode)),
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
