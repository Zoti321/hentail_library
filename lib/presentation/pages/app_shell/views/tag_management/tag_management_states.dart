import 'package:flutter/material.dart';
import 'package:hentai_library/config/theme.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'tag_management_styles.dart';
import '../../../../widgets/common/status/status_card_shell.dart';

class TagManagementLoadingCard extends StatelessWidget {
  const TagManagementLoadingCard({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return StatusCardShell(
      padding: TagManagementStyles.statusLoadingPadding,
      borderRadius: TagManagementStyles.statusCardRadius,
      child: Center(
        child: CircularProgressIndicator(
          strokeWidth: 2.2,
          color: theme.colorScheme.primary,
        ),
      ),
    );
  }
}

class TagManagementErrorCard extends StatelessWidget {
  const TagManagementErrorCard({super.key, required this.error});

  final Object error;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return StatusCardShell(
      padding: TagManagementStyles.statusErrorPadding,
      borderRadius: TagManagementStyles.statusCardRadius,
      child: Text(
        '$error',
        style: TextStyle(
          fontSize: TagManagementStyles.subtitleFontSize,
          color: theme.colorScheme.textTertiary,
        ),
      ),
    );
  }
}

class TagManagementEmptyState extends StatelessWidget {
  const TagManagementEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return StatusCardShell(
      padding: TagManagementStyles.statusEmptyPadding,
      borderRadius: TagManagementStyles.statusCardRadius,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            LucideIcons.tags,
            size: 32,
            color: cs.onSurfaceVariant,
          ),
          const SizedBox(height: 12),
          Text(
            '暂无标签',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: cs.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '你可以从这里添加、重命名或删除标签。',
            style: TextStyle(
              fontSize: TagManagementStyles.subtitleFontSize,
              color: cs.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

