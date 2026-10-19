import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/features/app_settings/presentation/app_data_wipe_flow.dart';
import 'package:hentai_library/core/l10n/app_localizations_x.dart';
import 'package:hentai_library/features/app_settings/presentation/log_export_flow.dart';
import 'package:hentai_library/shared/ui/theme/theme.dart';
import 'package:hentai_library/shared/ui/widgets/foundation/toggle_switch.dart';
import 'package:hentai_library/features/app_settings/presentation/view_models/diagnostic_mode_notifier.dart';
import 'package:hentai_library/shared/ui/widgets/settings/settings_layout_constants.dart';
import 'package:hentai_library/shared/ui/widgets/settings/settings_page_primitives.dart';
import 'package:hentai_library/shared/di/library_state_providers.dart';
import 'package:hentai_library/shared/di/settings_slot_providers.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class DiagnosticModeRow extends ConsumerWidget {
  const DiagnosticModeRow({required this.layoutTier, super.key});

  final SettingsLayoutTier layoutTier;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool enabled = ref.watch(diagnosticModeProvider);
    final ThemeData theme = Theme.of(context);
    final l10n = context.l10n;
    return SettingsRow(
      layoutTier: layoutTier,
      icon: Icon(
        LucideIcons.bug,
        size: 20,
        color: theme.hentai.iconDefault,
      ),
      label: l10n.settingsDiagnosticModeLabel,
      description: enabled
          ? l10n.settingsDiagnosticModeDescriptionEnabled
          : l10n.settingsDiagnosticModeDescriptionDisabled,
      action: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (enabled) ...<Widget>[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                l10n.settingsDiagnosticModeEnabledBadge,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          ToggleSwitch(
            checked: enabled,
            onChange: () =>
                ref.read(diagnosticModeProvider.notifier).setEnabled(!enabled),
          ),
        ],
      ),
    );
  }
}

class ExportLogsRow extends ConsumerWidget {
  const ExportLogsRow({required this.layoutTier, super.key});

  final SettingsLayoutTier layoutTier;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final bool diagnosticVerbose = ref.watch(diagnosticModeProvider);
    final l10n = context.l10n;
    return SettingsRow(
      layoutTier: layoutTier,
      icon: Icon(
        LucideIcons.fileArchive,
        size: 20,
        color: theme.hentai.iconDefault,
      ),
      label: l10n.settingsExportLogsLabel,
      description: l10n.settingsExportLogsDescription,
      onRowTap: () =>
          runLogExportFlow(context, diagnosticVerbose: diagnosticVerbose),
      action: Icon(
        LucideIcons.chevronRight,
        size: 16,
        color: theme.hentai.iconSecondary,
      ),
    );
  }
}

class ClearApplicationDataRow extends ConsumerWidget {
  const ClearApplicationDataRow({required this.layoutTier, super.key});

  final SettingsLayoutTier layoutTier;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final l10n = context.l10n;
    final bool syncRunning = ref.watch(libraryScanRunningStateProvider);
    return SettingsRow(
      layoutTier: layoutTier,
      isDestructive: true,
      icon: Icon(LucideIcons.trash2, size: 20, color: theme.colorScheme.error),
      label: l10n.settingsClearApplicationDataLabel,
      description: syncRunning
          ? l10n.settingsClearApplicationDataDisabledSyncRunning
          : l10n.settingsClearApplicationDataDescription,
      onRowTap: syncRunning
          ? null
          : () => runAppDataWipeFlow(
              context,
              readRecentMetadataBackupAt: ref.read(
                recentMetadataBackupAtReaderProvider,
              ),
            ),
      action: Icon(
        LucideIcons.chevronRight,
        size: 16,
        color: theme.hentai.iconSecondary,
      ),
    );
  }
}

class UninstallDataInfoRow extends ConsumerWidget {
  const UninstallDataInfoRow({required this.layoutTier, super.key});

  final SettingsLayoutTier layoutTier;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final l10n = context.l10n;
    return SettingsRow(
      layoutTier: layoutTier,
      icon: Icon(
        LucideIcons.info,
        size: 20,
        color: theme.hentai.iconDefault,
      ),
      label: l10n.settingsUninstallDataInfoLabel,
      description: l10n.settingsUninstallDataInfoDescription,
    );
  }
}
