import 'package:flutter/material.dart';
import 'package:hentai_library/core/l10n/app_localizations_x.dart';
import 'package:hentai_library/ui/core/widgets/overlays/context_menu/common.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

enum NamedFacetContextAction { rename, merge, delete }

class NamedFacetContextMenu {
  static void show(
    BuildContext context, {
    required Offset position,
    required ValueChanged<NamedFacetContextAction> onAction,
  }) {
    ContextMenuCommon.show(
      context,
      position: position,
      width: 236,
      height: 140,
      builder: (VoidCallback onClose) =>
          _MenuContent(onClose: onClose, onAction: onAction),
    );
  }
}

class _MenuContent extends StatelessWidget {
  const _MenuContent({required this.onClose, required this.onAction});

  final VoidCallback onClose;
  final ValueChanged<NamedFacetContextAction> onAction;

  void _handle(NamedFacetContextAction action) {
    onAction(action);
    onClose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return ContextMenuContainer(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            ContextMenuActionItem(
              icon: LucideIcons.pencil,
              label: l10n.metadataRename,
              onTap: () => _handle(NamedFacetContextAction.rename),
            ),
            ContextMenuActionItem(
              icon: LucideIcons.merge,
              label: l10n.metadataMerge,
              // Placeholder until core/FRB merge exists: #203.
              enabled: false,
              onTap: () {},
            ),
            ContextMenuActionItem(
              icon: LucideIcons.trash2,
              label: l10n.metadataDelete,
              isDestructive: true,
              onTap: () => _handle(NamedFacetContextAction.delete),
            ),
          ],
        ),
      ),
    );
  }
}
