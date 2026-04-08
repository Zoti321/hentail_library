import 'package:flutter/material.dart';
import 'package:hentai_library/config/theme.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

enum ComicContextAction {
  read,
  detail,
  edit,
  openFolder,
  delete,
}

class FluentContextMenu {
  static void show(
    BuildContext context, {
    required Offset position,
    required String mangaTitle,
    required ValueChanged<ComicContextAction> onAction,
  }) {
    final OverlayState overlay = Overlay.of(context);
    late OverlayEntry entry;
    final Size screenSize = MediaQuery.of(context).size;
    double left = position.dx;
    double top = position.dy;
    const double width = 236;
    const double height = 320;
    if (left + width > screenSize.width) {
      left = screenSize.width - width - 10;
    }
    if (top + height > screenSize.height) {
      top = screenSize.height - height - 10;
    }
    entry = OverlayEntry(
      builder: (BuildContext context) => Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: () => entry.remove(),
              onSecondaryTap: () => entry.remove(),
            ),
          ),
          Positioned(
            left: left,
            top: top,
            child: Material(
              color: Colors.transparent,
              child: _MenuContent(
                title: mangaTitle,
                onClose: () => entry.remove(),
                onAction: onAction,
              ),
            ),
          ),
        ],
      ),
    );
    overlay.insert(entry);
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
    final ColorScheme cs = Theme.of(context).colorScheme;
    return Container(
      width: 236,
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.borderSubtle),
        boxShadow: [
          BoxShadow(
            color: cs.cardShadowHover,
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest,
                border: Border(bottom: BorderSide(color: cs.borderSubtle)),
              ),
              child: Row(
                children: [
                  Icon(LucideIcons.panelRightOpen, size: 13, color: cs.iconSecondary),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: cs.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            _MenuGroupLabel(label: '快速操作', color: cs.textSecondary),
            _FluentMenuItem(
              icon: LucideIcons.bookOpen,
              label: '阅读',
              shortcut: 'Enter',
              onTap: () => _handle(ComicContextAction.read),
            ),
            _FluentMenuItem(
              icon: LucideIcons.info,
              label: '查看详情',
              onTap: () => _handle(ComicContextAction.detail),
            ),
            Divider(height: 10, thickness: 1, color: cs.surfaceContainerHighest),
            _MenuGroupLabel(label: '管理', color: cs.textSecondary),
            _FluentMenuItem(
              icon: LucideIcons.squarePen,
              label: '编辑元数据',
              onTap: () => _handle(ComicContextAction.edit),
            ),
            _FluentMenuItem(
              icon: LucideIcons.externalLink,
              label: '打开文件夹',
              onTap: () => _handle(ComicContextAction.openFolder),
            ),
            Divider(height: 10, thickness: 1, color: cs.surfaceContainerHighest),
            _MenuGroupLabel(label: '危险操作', color: cs.error),
            _FluentMenuItem(
              icon: LucideIcons.trash2,
              label: '删除',
              shortcut: 'Del',
              isDestructive: true,
              onTap: () => _handle(ComicContextAction.delete),
            ),
            const SizedBox(height: 6),
          ],
        ),
      ),
    );
  }
}

class _MenuGroupLabel extends StatelessWidget {
  const _MenuGroupLabel({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 4),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.4,
          color: color,
        ),
      ),
    );
  }
}

class _FluentMenuItem extends StatelessWidget {
  const _FluentMenuItem({
    required this.icon,
    required this.label,
    this.shortcut,
    required this.onTap,
    this.isDestructive = false,
  });

  final IconData icon;
  final String label;
  final String? shortcut;
  final VoidCallback onTap;
  final bool isDestructive;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          hoverColor: isDestructive ? cs.error.withAlpha(10) : cs.buttonPressed,
          splashFactory: NoSplash.splashFactory,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 16,
                  color: isDestructive ? cs.error : cs.textSecondary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: isDestructive ? cs.error : cs.textPrimary,
                    ),
                  ),
                ),
                if (shortcut != null)
                  Text(
                    shortcut!,
                    style: TextStyle(
                      fontSize: 11,
                      color: cs.textDisabled,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
