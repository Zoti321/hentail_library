import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/core/l10n/app_localizations.dart';
import 'package:hentai_library/core/l10n/app_localizations_x.dart';
import 'package:hentai_library/core/metadata/metadata_export_flow.dart';
import 'package:hentai_library/core/metadata/metadata_export_options.dart';
import 'package:hentai_library/ui/core/theme/theme.dart';
import 'package:hentai_library/ui/core/widgets/foundation/toggle_switch.dart';
import 'package:hentai_library/ui/features/settings/view_models/metadata_auto_backup_notifier.dart';
import 'package:hentai_library/ui/features/settings/views/settings_page/widgets/settings_layout_constants.dart';
import 'package:hentai_library/ui/features/settings/views/settings_page/widgets/settings_page_primitives.dart';
import 'package:hentai_library/ui/features/shell/view_models/current_library_notifier.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

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
      future: _metadataBackupsDirectory(),
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

Future<String> _metadataBackupsDirectory() async {
  final directory = await getApplicationSupportDirectory();
  return p.join(directory.path, 'metadata_backups');
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
        onChange: () => ref
            .read(metadataAutoBackupProvider.notifier)
            .setEnabled(!enabled),
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

class MetadataBackupLastBackupRow extends StatelessWidget {
  const MetadataBackupLastBackupRow({required this.layoutTier, super.key});

  final SettingsLayoutTier layoutTier;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final ThemeData theme = Theme.of(context);
    return SettingsRow(
      layoutTier: layoutTier,
      icon: Icon(
        LucideIcons.clock,
        size: 20,
        color: theme.colorScheme.hentai.iconDefault,
      ),
      label: l10n.settingsMetadataBackupLastBackupLabel,
      description: l10n.settingsMetadataBackupLastBackupEmpty,
    );
  }
}

class MetadataBackupNowRow extends StatelessWidget {
  const MetadataBackupNowRow({required this.layoutTier, super.key});

  final SettingsLayoutTier layoutTier;

  @override
  Widget build(BuildContext context) {
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
        initialOptions: MetadataExportOptions(
          libraryId: currentLibraryId,
        ),
      ),
      action: Icon(
        LucideIcons.chevronRight,
        size: 16,
        color: theme.colorScheme.hentai.iconSecondary,
      ),
    );
  }
}
