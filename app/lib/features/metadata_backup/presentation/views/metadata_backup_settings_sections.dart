import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/core/l10n/app_localizations.dart';
import 'package:hentai_library/core/l10n/app_localizations_x.dart';
import 'package:hentai_library/core/util/utils.dart';
import 'package:hentai_library/features/metadata_backup/presentation/providers/metadata_backup_use_case_providers.dart';
import 'package:hentai_library/features/metadata_backup/domain/metadata_export_options.dart';
import 'package:hentai_library/features/metadata_backup/presentation/metadata_export_flow.dart';
import 'package:hentai_library/features/metadata_backup/presentation/metadata_import_flow.dart';
import 'package:hentai_library/features/metadata_backup/presentation/view_models/metadata_auto_backup_coordinator_notifier.dart';
import 'package:hentai_library/features/metadata_backup/presentation/view_models/metadata_auto_backup_notifier.dart';
import 'package:hentai_library/features/metadata_backup/presentation/view_models/metadata_last_auto_backup_notifier.dart';
import 'package:hentai_library/shared/ui/widgets/settings/settings_list.dart';
import 'package:hentai_library/shared/ui/widgets/settings/settings_tile.dart';
import 'package:hentai_library/shared/ui/widgets/feedback/app_snackbar.dart';
import 'package:intl/intl.dart';
import 'package:material_symbols_icons/symbols.dart';

/// 设置 → 元数据备份分类（MD3E）：自动备份、手动备份与导入导出。
class MetadataBackupSettingsSections extends ConsumerWidget {
  const MetadataBackupSettingsSections({super.key});

  Future<void> _backupNow(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
  ) async {
    await ref.read(metadataAutoBackupCoordinatorProvider.notifier).backupNow();
    if (context.mounted) {
      showSuccessSnackbar(context, l10n.settingsMetadataBackupNowSuccess);
    }
  }

  Future<void> _openBackupFolder(BuildContext context, String path) async {
    try {
      await openDirectoryInFileExplorer(path);
    } catch (e) {
      if (context.mounted) {
        showErrorSnackbar(context, e);
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = context.l10n;
    return FutureBuilder<String>(
      future: ref.read(metadataBackupDirectoryQueryProvider)(),
      builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
        final String storagePath =
            snapshot.data ?? l10n.settingsMetadataBackupStoragePathLoading;
        final bool autoEnabled =
            ref.watch(metadataAutoBackupProvider).asData?.value ?? true;
        final DateTime? lastBackup = ref
            .watch(metadataLastAutoBackupProvider)
            .asData
            ?.value;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            SettingsSection(
              title: Text(l10n.settingsMetadataBackupAutoGroupTitle),
              tiles: <Widget>[
                SettingsSwitchTile(
                  leading: Symbols.hard_drive,
                  title: Text(l10n.settingsMetadataBackupAutoToggleLabel),
                  description: Text(
                    l10n.settingsMetadataBackupAutoToggleDescription,
                  ),
                  value: autoEnabled,
                  onChanged: (bool value) => ref
                      .read(metadataAutoBackupProvider.notifier)
                      .setEnabled(value),
                ),
                SettingsNavigationTile(
                  leading: Symbols.folder,
                  title: Text(l10n.settingsMetadataBackupStoragePathLabel),
                  description: Text(storagePath),
                ),
                SettingsNavigationTile(
                  leading: Symbols.schedule,
                  title: Text(l10n.settingsMetadataBackupLastBackupLabel),
                  description: Text(
                    lastBackup == null
                        ? l10n.settingsMetadataBackupLastBackupEmpty
                        : l10n.settingsMetadataBackupLastBackupAt(
                            DateFormat('yyyy-MM-dd HH:mm').format(lastBackup),
                          ),
                  ),
                ),
              ],
            ),
            SettingsSection(
              title: Text(l10n.settingsMetadataBackupManualGroupTitle),
              tiles: <Widget>[
                SettingsNavigationTile(
                  leading: Symbols.save,
                  title: Text(l10n.settingsMetadataBackupNowLabel),
                  description: Text(l10n.settingsMetadataBackupNowDescription),
                  onTap: () => _backupNow(context, ref, l10n),
                ),
                if (isDesktop)
                  SettingsNavigationTile(
                    leading: Symbols.folder_open,
                    title: Text(l10n.settingsMetadataBackupOpenFolderLabel),
                    description: Text(
                      l10n.settingsMetadataBackupOpenFolderDescription,
                    ),
                    onTap: () => _openBackupFolder(context, storagePath),
                  ),
                SettingsNavigationTile(
                  leading: Symbols.upload,
                  title: Text(l10n.settingsMetadataBackupExportLabel),
                  description: Text(
                    l10n.settingsMetadataBackupExportDescription,
                  ),
                  onTap: () => runMetadataExportFlow(
                    context,
                    initialOptions: const MetadataExportOptions(),
                  ),
                ),
                SettingsNavigationTile(
                  leading: Symbols.download,
                  title: Text(l10n.settingsMetadataBackupImportLabel),
                  description: Text(
                    l10n.settingsMetadataBackupImportDescription,
                  ),
                  onTap: () => runMetadataImportFlow(context),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}
