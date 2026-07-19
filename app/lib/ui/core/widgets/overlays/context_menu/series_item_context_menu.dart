import 'package:flutter/material.dart';
import 'package:hentai_library/core/l10n/app_localizations_x.dart';
import 'package:hentai_library/ui/core/widgets/overlays/context_menu/common.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

enum SeriesItemContextAction { goToDetail, showInExplorer }

class SeriesItemContextMenu {
  static void show(
    BuildContext context, {
    required Offset position,
    required String comicTitle,
    required ValueChanged<SeriesItemContextAction> onAction,
  }) {
    ContextMenuCommon.show(
      context,
      position: position,
      width: 236,
      height: 150,
      builder: (VoidCallback onClose) =>
          _MenuContent(title: comicTitle, onClose: onClose, onAction: onAction),
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
  final ValueChanged<SeriesItemContextAction> onAction;

  void handleAction(SeriesItemContextAction action) {
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
              icon: LucideIcons.info,
              label: l10n.contextMenuGoToDetail,
              onTap: () => handleAction(SeriesItemContextAction.goToDetail),
            ),
            ContextMenuActionItem(
              icon: LucideIcons.externalLink,
              label: l10n.comicDetailShowInExplorer,
              onTap: () => handleAction(SeriesItemContextAction.showInExplorer),
            ),
          ],
        ),
      ),
    );
  }
}
