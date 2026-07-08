import 'package:flutter/material.dart';
import 'package:hentai_library/ui/core/theme/theme.dart';
import 'package:hentai_library/ui/core/widgets/actions/ghost_button.dart';
import 'package:hentai_library/ui/features/metadata/views/metadata_page/widgets/metadata_layout_constants.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class MetadataPanelRowActions extends StatelessWidget {
  const MetadataPanelRowActions({
    required this.layoutTier,
    required this.onRename,
    required this.onDelete,
    this.iconButtonRadius = 8,
    this.iconButtonSize = 28,
    super.key,
  });

  final MetadataLayoutTier layoutTier;
  final VoidCallback onRename;
  final VoidCallback onDelete;
  final double iconButtonRadius;
  final double iconButtonSize;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;

    if (metadataRowUsesOverflowMenu(layoutTier)) {
      return PopupMenuButton<_MetadataRowMenuAction>(
        tooltip: '更多操作',
        icon: Icon(
          LucideIcons.ellipsisVertical,
          size: 16,
          color: cs.hentai.iconDefault,
        ),
        padding: EdgeInsets.zero,
        constraints: BoxConstraints.tightFor(
          width: iconButtonSize,
          height: iconButtonSize,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(iconButtonRadius),
        ),
        onSelected: (_MetadataRowMenuAction action) {
          switch (action) {
            case _MetadataRowMenuAction.rename:
              onRename();
            case _MetadataRowMenuAction.delete:
              onDelete();
          }
        },
        itemBuilder: (BuildContext context) {
          return <PopupMenuEntry<_MetadataRowMenuAction>>[
            const PopupMenuItem<_MetadataRowMenuAction>(
              value: _MetadataRowMenuAction.rename,
              child: Text('重命名'),
            ),
            PopupMenuItem<_MetadataRowMenuAction>(
              value: _MetadataRowMenuAction.delete,
              child: Text(
                '删除',
                style: TextStyle(color: cs.error),
              ),
            ),
          ];
        },
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        GhostButton.icon(
          icon: LucideIcons.squarePen,
          iconSize: 16,
          size: iconButtonSize,
          borderRadius: iconButtonRadius,
          tooltip: '重命名',
          delayTooltipThreeSeconds: true,
          hoverColor: cs.primary.withAlpha(10),
          overlayColor: cs.primary.withAlpha(14),
          onPressed: onRename,
        ),
        GhostButton.icon(
          tooltip: '删除',
          semanticLabel: '删除',
          icon: LucideIcons.trash2,
          iconSize: 16,
          size: iconButtonSize,
          borderRadius: iconButtonRadius,
          foregroundColor: cs.error,
          hoverColor: cs.primary.withAlpha(10),
          overlayColor: cs.primary.withAlpha(14),
          delayTooltipThreeSeconds: true,
          onPressed: onDelete,
        ),
      ],
    );
  }
}

enum _MetadataRowMenuAction { rename, delete }
