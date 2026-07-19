import 'package:flutter/material.dart';
import 'package:hentai_library/core/l10n/app_localizations_x.dart';
import 'package:hentai_library/ui/core/widgets/overlays/context_menu/common.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

enum ComicContextAction { read, edit, showInExplorer, delete }

class ComicContextMenu {
  static void show(
    BuildContext context, {
    required Offset position,
    required String mangaTitle,
    required ValueChanged<ComicContextAction> onAction,
  }) {
    ContextMenuCommon.show(
      context,
      position: position,
      width: 236,
      height: 240,
      builder: (VoidCallback onClose) =>
          _MenuContent(title: mangaTitle, onClose: onClose, onAction: onAction),
    );
  }
}

class _MenuContent extends StatelessWidget {
  const _MenuContent({
    required this.title,
    required this.onClose,
    required this.onAction,
  });

  final String title;
  final VoidCallback onClose;
  final ValueChanged<ComicContextAction> onAction;

  void _handle(ComicContextAction action) {
    onAction(action);
    onClose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return ContextMenuContainer(
      title: title,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            ContextMenuActionItem(
              icon: LucideIcons.bookOpen,
              label: l10n.comicDetailRead,
              onTap: () => _handle(ComicContextAction.read),
            ),
            ContextMenuActionItem(
              icon: LucideIcons.squarePen,
              label: l10n.comicDetailEditMetadata,
              onTap: () => _handle(ComicContextAction.edit),
            ),
            ContextMenuActionItem(
              icon: LucideIcons.externalLink,
              label: l10n.comicDetailShowInExplorer,
              onTap: () => _handle(ComicContextAction.showInExplorer),
            ),
            ContextMenuActionItem(
              icon: LucideIcons.trash2,
              label: l10n.comicDetailDelete,
              isDestructive: true,
              onTap: () => _handle(ComicContextAction.delete),
            ),
          ],
        ),
      ),
    );
  }
}
