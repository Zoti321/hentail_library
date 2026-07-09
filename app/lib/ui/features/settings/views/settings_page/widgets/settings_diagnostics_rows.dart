import 'package:flutter/material.dart';
import 'package:hentai_library/core/logging/log_export_flow.dart';
import 'package:hentai_library/ui/core/theme/theme.dart';
import 'package:hentai_library/ui/features/settings/views/settings_page/widgets/settings_layout_constants.dart';
import 'package:hentai_library/ui/features/settings/views/settings_page/widgets/settings_page_primitives.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class ExportLogsRow extends StatelessWidget {
  const ExportLogsRow({required this.layoutTier, super.key});

  final SettingsLayoutTier layoutTier;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return SettingsRow(
      layoutTier: layoutTier,
      icon: Icon(
        LucideIcons.fileArchive,
        size: 20,
        color: theme.colorScheme.hentai.iconDefault,
      ),
      label: '导出日志',
      description: '打包应用与核心日志，便于问题反馈',
      onRowTap: () => runLogExportFlow(context),
      action: Icon(
        LucideIcons.chevronRight,
        size: 16,
        color: theme.colorScheme.hentai.iconSecondary,
      ),
    );
  }
}
