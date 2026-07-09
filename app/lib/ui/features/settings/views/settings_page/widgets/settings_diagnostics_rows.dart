import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/core/logging/log_export_flow.dart';
import 'package:hentai_library/ui/core/theme/theme.dart';
import 'package:hentai_library/ui/core/widgets/foundation/toggle_switch.dart';
import 'package:hentai_library/ui/features/settings/state/diagnostic_mode_notifier.dart';
import 'package:hentai_library/ui/features/settings/views/settings_page/widgets/settings_layout_constants.dart';
import 'package:hentai_library/ui/features/settings/views/settings_page/widgets/settings_page_primitives.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class DiagnosticModeRow extends ConsumerWidget {
  const DiagnosticModeRow({required this.layoutTier, super.key});

  final SettingsLayoutTier layoutTier;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool enabled = ref.watch(diagnosticModeProvider);
    final ThemeData theme = Theme.of(context);
    return SettingsRow(
      layoutTier: layoutTier,
      icon: Icon(
        LucideIcons.bug,
        size: 20,
        color: theme.colorScheme.hentai.iconDefault,
      ),
      label: '详细诊断',
      description: enabled
          ? '已开启：Dart 与 Rust 记录更详细日志'
          : '临时提高日志详细程度，便于复现问题',
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
                '已开启',
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
            onChange: () => ref
                .read(diagnosticModeProvider.notifier)
                .setEnabled(!enabled),
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
    return SettingsRow(
      layoutTier: layoutTier,
      icon: Icon(
        LucideIcons.fileArchive,
        size: 20,
        color: theme.colorScheme.hentai.iconDefault,
      ),
      label: '导出日志',
      description: '打包应用与核心日志，便于问题反馈',
      onRowTap: () => runLogExportFlow(
        context,
        diagnosticVerbose: diagnosticVerbose,
      ),
      action: Icon(
        LucideIcons.chevronRight,
        size: 16,
        color: theme.colorScheme.hentai.iconSecondary,
      ),
    );
  }
}
