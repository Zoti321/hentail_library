import 'package:flutter/material.dart';
import 'package:hentai_library/config/theme.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../tag_management_styles.dart';

class TagListCard extends StatelessWidget {
  const TagListCard({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Container(
      margin: const EdgeInsets.only(top: 16),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(TagManagementStyles.listRadius),
        border: Border.all(color: cs.borderSubtle),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(TagManagementStyles.listRadius),
        child: child,
      ),
    );
  }
}

class TagListHeader extends StatelessWidget {
  const TagListHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Container(
      padding: TagManagementStyles.listHeaderPadding,
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        border: Border(bottom: BorderSide(color: cs.borderSubtle)),
      ),
      child: Row(
        children: [
          Icon(
            LucideIcons.tags,
            size: TagManagementStyles.listHeaderIconSize,
            color: cs.onSurfaceVariant,
          ),
          const SizedBox(width: 8),
          Text(
            '全部标签',
            style: TextStyle(
              fontSize: TagManagementStyles.listHeaderFontSize,
              fontWeight: FontWeight.w600,
              color: cs.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

