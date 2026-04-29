import 'package:flutter/material.dart';
import 'package:hentai_library/presentation/theme/theme.dart';
import 'package:hentai_library/presentation/ui/desktop/widgets/overlays/context_menu/common.dart';
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
      height: 280,
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
    final ColorScheme cs = Theme.of(context).colorScheme;
    final AppThemeTokens tokens = context.tokens;
    return ContextMenuContainer(
      title: title,
      leadingIcon: LucideIcons.panelRightOpen,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(height: tokens.spacing.xs + 2),
          _FluentMenuItem(
            icon: LucideIcons.bookOpen,
            label: '阅读',
            shortcut: 'Enter',
            onTap: () => _handle(ComicContextAction.read),
          ),
          Divider(height: 14, thickness: 1.4, color: cs.hentai.borderMedium),
          _FluentMenuItem(
            icon: LucideIcons.squarePen,
            label: '编辑元数据',
            onTap: () => _handle(ComicContextAction.edit),
          ),
          _FluentMenuItem(
            icon: LucideIcons.externalLink,
            label: '在文件资源管理器中显示',
            onTap: () => _handle(ComicContextAction.showInExplorer),
          ),
          Divider(height: 14, thickness: 1.4, color: cs.hentai.borderMedium),
          _FluentMenuItem(
            icon: LucideIcons.trash2,
            label: '删除',
            shortcut: 'Del',
            isDestructive: true,
            onTap: () => _handle(ComicContextAction.delete),
          ),
          SizedBox(height: tokens.spacing.xs + 2),
        ],
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
    final AppThemeTokens tokens = context.tokens;
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: tokens.spacing.xs + 2,
        vertical: 1,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(tokens.radius.md),
          hoverColor: isDestructive
              ? cs.hentai.warning.withAlpha(16)
              : cs.hentai.hoverBackground,
          splashFactory: NoSplash.splashFactory,
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: tokens.spacing.sm + 2,
              vertical: tokens.spacing.sm,
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 16,
                  color: isDestructive
                      ? cs.hentai.warning
                      : cs.hentai.textSecondary,
                ),
                SizedBox(width: tokens.spacing.md),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: tokens.text.bodySm,
                      fontWeight: FontWeight.w500,
                      color: isDestructive
                          ? cs.hentai.warning
                          : cs.hentai.textPrimary,
                    ),
                  ),
                ),
                if (shortcut != null)
                  Text(
                    shortcut!,
                    style: TextStyle(
                      fontSize: tokens.text.labelXs - 1,
                      color: cs.hentai.textDisabled,
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
