import 'package:flutter/material.dart';
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
              label: '阅读',
              onTap: () => _handle(ComicContextAction.read),
            ),
            ContextMenuActionItem(
              icon: LucideIcons.squarePen,
              label: '编辑元数据',
              onTap: () => _handle(ComicContextAction.edit),
            ),
            ContextMenuActionItem(
              icon: LucideIcons.externalLink,
              label: '在文件资源管理器中显示',
              onTap: () => _handle(ComicContextAction.showInExplorer),
            ),
            ContextMenuActionItem(
              icon: LucideIcons.trash2,
              label: '删除',
              isDestructive: true,
              onTap: () => _handle(ComicContextAction.delete),
            ),
          ],
        ),
      ),
    );
  }
}
