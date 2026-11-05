import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/core/l10n/app_localizations.dart';
import 'package:hentai_library/core/l10n/app_localizations_x.dart';
import 'package:hentai_library/core/util/utils.dart';
import 'package:hentai_library/features/metadata_backup/data/metadata_backup_paths.dart';
import 'package:hentai_library/features/metadata_backup/domain/metadata_export_options.dart';
import 'package:hentai_library/features/metadata_backup/presentation/metadata_export_flow.dart';
import 'package:hentai_library/features/metadata_backup/presentation/metadata_import_flow.dart';
import 'package:hentai_library/features/metadata_backup/presentation/view_models/metadata_auto_backup_coordinator_notifier.dart';
import 'package:hentai_library/features/metadata_backup/presentation/view_models/metadata_auto_backup_notifier.dart';
import 'package:hentai_library/features/metadata_backup/presentation/view_models/metadata_last_auto_backup_notifier.dart';
import 'package:hentai_library/shared/ui/widgets/settings/settings_list.dart';
import 'package:hentai_library/shared/ui/widgets/settings/settings_tile.dart';
import 'package:hentai_library/shared/di/library_state_providers.dart';
import 'package:hentai_library/shared/ui/widgets/feedback/app_snackbar.dart';
import 'package:intl/intl.dart';
import 'package:material_symbols_icons/symbols.dart';

/// 设置 → 元数据备份分类（MD3E）：自动备份、手动备份与导入导出。
class MetadataBackupSettingsSections extends ConsumerWidget {
  const MetadataBackupSettingsSections({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = context.l10n;
    return FutureBuilder<String>(
      future: metadataBackupsDirectory(),
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
            Md3eSettingsSection(
              title: Text(l10n.settingsMetadataBackupAutoGroupTitle),
              tiles: <Widget>[
                Md3eSettingsSwitchTile(
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
                Md3eSettingsNavigationTile(
                  leading: Symbols.folder,
                  title: Text(l10n.settingsMetadataBackupStoragePathLabel),
                  description: Text(storagePath),
                ),
                Md3eSettingsNavigationTile(
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
            Md3eSettingsSection(
              title: Text(l10n.settingsMetadataBackupManualGroupTitle),
              tiles: <Widget>[
                Md3eSettingsNavigationTile(
                  leading: Symbols.save,
                  title: Text(l10n.settingsMetadataBackupNowLabel),
                  description: Text(l10n.settingsMetadataBackupNowDescription),
                  onTap: () async {
                    await ref
                        .read(metadataAutoBackupCoordinatorProvider.notifier)
                        .backupNow();
                    if (context.mounted) {
                      showSuccessSnackbar(
                        context,
                        l10n.settingsMetadataBackupNowSuccess,
                      );
                    }
                  },
                ),
                if (isDesktop)
                  Md3eSettingsNavigationTile(
                    leading: Symbols.folder_open,
                    title: Text(l10n.settingsMetadataBackupOpenFolderLabel),
                    description: Text(
                      l10n.settingsMetadataBackupOpenFolderDescription,
                    ),
                    onTap: () async {
                      try {
                        await openDirectoryInFileExplorer(storagePath);
                      } catch (e) {
                        if (context.mounted) {
                          showErrorSnackbar(context, e);
                        }
                      }
                    },
                  ),
                Md3eSettingsNavigationTile(
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
                Md3eSettingsNavigationTile(
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
