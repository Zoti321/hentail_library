import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/core/l10n/app_localizations.dart';
import 'package:hentai_library/core/l10n/app_localizations_x.dart';
import 'package:hentai_library/core/metadata/metadata_backup_paths.dart';
import 'package:hentai_library/core/metadata/metadata_export_flow.dart';
import 'package:hentai_library/core/metadata/metadata_export_options.dart';
import 'package:hentai_library/core/metadata/metadata_import_flow.dart';
import 'package:hentai_library/core/util/utils.dart';
import 'package:hentai_library/ui/core/theme/theme.dart';
import 'package:hentai_library/ui/core/widgets/feedback/custom_toast.dart';
import 'package:hentai_library/ui/core/widgets/foundation/toggle_switch.dart';
import 'package:hentai_library/ui/features/settings/view_models/metadata_auto_backup_coordinator_notifier.dart';
import 'package:hentai_library/ui/features/settings/view_models/metadata_auto_backup_notifier.dart';
import 'package:hentai_library/ui/features/settings/view_models/metadata_last_auto_backup_notifier.dart';
import 'package:hentai_library/ui/features/settings/views/settings_page/widgets/settings_layout_constants.dart';
import 'package:hentai_library/ui/features/settings/views/settings_page/widgets/settings_page_primitives.dart';
import 'package:hentai_library/ui/features/shell/view_models/current_library_notifier.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class MetadataBackupSettingsDetail extends ConsumerWidget {
  const MetadataBackupSettingsDetail({
    required this.layoutTier,
    required this.showTitle,
    super.key,
  });

  final SettingsLayoutTier layoutTier;
  final bool showTitle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = context.l10n;
    final AppThemeTokens tokens = context.tokens;
    final ColorScheme cs = Theme.of(context).colorScheme;

    return FutureBuilder<String>(
      future: metadataBackupsDirectory(),
      builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
        final String storagePath =
            snapshot.data ?? l10n.settingsMetadataBackupStoragePathLoading;
        final Widget content = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: tokens.spacing.lg,
          children: <Widget>[
            SettingsGroup(
              title: l10n.settingsMetadataBackupAutoGroupTitle,
              children: <Widget>[
                MetadataAutoBackupToggleRow(layoutTier: layoutTier),
                MetadataBackupStoragePathRow(
                  layoutTier: layoutTier,
                  storagePath: storagePath,
                ),
                MetadataBackupLastBackupRow(layoutTier: layoutTier),
                MetadataBackupNowRow(layoutTier: layoutTier),
                if (isDesktop)
                  MetadataBackupOpenFolderRow(
                    layoutTier: layoutTier,
                    storagePath: storagePath,
                  ),
              ],
            ),
            SettingsGroup(
              title: l10n.settingsMetadataBackupManualGroupTitle,
              children: <Widget>[
                MetadataExportRow(
                  layoutTier: layoutTier,
                  currentLibraryId: ref
                      .watch(currentLibraryProvider)
                      .asData
                      ?.value
                      .currentId,
                ),
                MetadataImportRow(layoutTier: layoutTier),
              ],
            ),
          ],
        );

        if (!showTitle) {
          return content;
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: tokens.spacing.lg,
          children: <Widget>[
            Text(
              l10n.settingsGroupMetadataBackup,
              style: TextStyle(
                fontSize: settingsPageTitleFontSize(layoutTier),
                fontWeight: FontWeight.w600,
                letterSpacing: -0.4,
                color: cs.hentai.textPrimary,
              ),
            ),
            content,
          ],
        );
      },
    );
  }
}

class MetadataAutoBackupToggleRow extends ConsumerWidget {
  const MetadataAutoBackupToggleRow({required this.layoutTier, super.key});

  final SettingsLayoutTier layoutTier;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<bool> enabledAsync = ref.watch(metadataAutoBackupProvider);
    final AppLocalizations l10n = context.l10n;
    final ThemeData theme = Theme.of(context);
    final bool enabled = enabledAsync.asData?.value ?? true;

    return SettingsRow(
      layoutTier: layoutTier,
      icon: Icon(
        LucideIcons.hardDrive,
        size: 20,
        color: theme.colorScheme.hentai.iconDefault,
      ),
      label: l10n.settingsMetadataBackupAutoToggleLabel,
      description: l10n.settingsMetadataBackupAutoToggleDescription,
      action: ToggleSwitch(
        checked: enabled,
        onChange: () =>
            ref.read(metadataAutoBackupProvider.notifier).setEnabled(!enabled),
      ),
    );
  }
}

class MetadataBackupStoragePathRow extends StatelessWidget {
  const MetadataBackupStoragePathRow({
    required this.layoutTier,
    required this.storagePath,
    super.key,
  });

  final SettingsLayoutTier layoutTier;
  final String storagePath;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final ThemeData theme = Theme.of(context);
    return SettingsRow(
      layoutTier: layoutTier,
      icon: Icon(
        LucideIcons.folder,
        size: 20,
        color: theme.colorScheme.hentai.iconDefault,
      ),
      label: l10n.settingsMetadataBackupStoragePathLabel,
      description: storagePath,
    );
  }
}

class MetadataBackupLastBackupRow extends ConsumerWidget {
  const MetadataBackupLastBackupRow({required this.layoutTier, super.key});

  final SettingsLayoutTier layoutTier;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = context.l10n;
    final ThemeData theme = Theme.of(context);
    final DateTime? lastBackup = ref
        .watch(metadataLastAutoBackupProvider)
        .asData
        ?.value;
    final String description = lastBackup == null
        ? l10n.settingsMetadataBackupLastBackupEmpty
        : l10n.settingsMetadataBackupLastBackupAt(
            DateFormat('yyyy-MM-dd HH:mm').format(lastBackup),
          );

    return SettingsRow(
      layoutTier: layoutTier,
      icon: Icon(
        LucideIcons.clock,
        size: 20,
        color: theme.colorScheme.hentai.iconDefault,
      ),
      label: l10n.settingsMetadataBackupLastBackupLabel,
      description: description,
    );
  }
}

class MetadataBackupNowRow extends ConsumerWidget {
  const MetadataBackupNowRow({required this.layoutTier, super.key});

  final SettingsLayoutTier layoutTier;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = context.l10n;
    final ThemeData theme = Theme.of(context);
    return SettingsRow(
      layoutTier: layoutTier,
      icon: Icon(
        LucideIcons.save,
        size: 20,
        color: theme.colorScheme.hentai.iconDefault,
      ),
      label: l10n.settingsMetadataBackupNowLabel,
      description: l10n.settingsMetadataBackupNowDescription,
      onRowTap: () async {
        await ref
            .read(metadataAutoBackupCoordinatorProvider.notifier)
            .backupNow();
        if (context.mounted) {
          showSuccessToast(context, l10n.settingsMetadataBackupNowSuccess);
        }
      },
      action: Icon(
        LucideIcons.chevronRight,
        size: 16,
        color: theme.colorScheme.hentai.iconSecondary,
      ),
    );
  }
}

class MetadataBackupOpenFolderRow extends StatelessWidget {
  const MetadataBackupOpenFolderRow({
    required this.layoutTier,
    required this.storagePath,
    super.key,
  });

  final SettingsLayoutTier layoutTier;
  final String storagePath;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final ThemeData theme = Theme.of(context);
    return SettingsRow(
      layoutTier: layoutTier,
      icon: Icon(
        LucideIcons.folderOpen,
        size: 20,
        color: theme.colorScheme.hentai.iconDefault,
      ),
      label: l10n.settingsMetadataBackupOpenFolderLabel,
      description: l10n.settingsMetadataBackupOpenFolderDescription,
      onRowTap: () async {
        try {
          await openDirectoryInFileExplorer(storagePath);
        } catch (e) {
          if (context.mounted) {
            showErrorToast(context, e);
          }
        }
      },
      action: Icon(
        LucideIcons.chevronRight,
        size: 16,
        color: theme.colorScheme.hentai.iconSecondary,
      ),
    );
  }
}

class MetadataExportRow extends ConsumerWidget {
  const MetadataExportRow({
    required this.layoutTier,
    required this.currentLibraryId,
    super.key,
  });

  final SettingsLayoutTier layoutTier;
  final String? currentLibraryId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = context.l10n;
    final ThemeData theme = Theme.of(context);
    return SettingsRow(
      layoutTier: layoutTier,
      icon: Icon(
        LucideIcons.upload,
        size: 20,
        color: theme.colorScheme.hentai.iconDefault,
      ),
      label: l10n.settingsMetadataBackupExportLabel,
      description: l10n.settingsMetadataBackupExportDescription,
      onRowTap: () => runMetadataExportFlow(
        context,
        initialOptions: MetadataExportOptions(libraryId: currentLibraryId),
      ),
      action: Icon(
        LucideIcons.chevronRight,
        size: 16,
        color: theme.colorScheme.hentai.iconSecondary,
      ),
    );
  }
}

class MetadataImportRow extends StatelessWidget {
  const MetadataImportRow({required this.layoutTier, super.key});

  final SettingsLayoutTier layoutTier;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final ThemeData theme = Theme.of(context);
    return SettingsRow(
      layoutTier: layoutTier,
      icon: Icon(
        LucideIcons.download,
        size: 20,
        color: theme.colorScheme.hentai.iconDefault,
      ),
      label: l10n.settingsMetadataBackupImportLabel,
      description: l10n.settingsMetadataBackupImportDescription,
      onRowTap: () => runMetadataImportFlow(context),
      action: Icon(
        LucideIcons.chevronRight,
        size: 16,
        color: theme.colorScheme.hentai.iconSecondary,
      ),
    );
  }
}
