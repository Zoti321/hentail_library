import 'package:flutter/material.dart';
import 'package:hentai_library/theme/theme.dart';
import 'package:hentai_library/presentation/ui/desktop/widgets/overlays/context_menu/common.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

enum SeriesContextAction { read, reorder, addComics, rename, delete }

class SeriesContextMenu {
  static void show(
    BuildContext context, {
    required Offset position,
    required String seriesName,
    required ValueChanged<SeriesContextAction> onAction,
  }) {
    ContextMenuCommon.show(
      context,
      position: position,
      width: 236,
      height: 286,
      builder: (VoidCallback onClose) => _MenuContent(
        title: seriesName,
        onClose: onClose,
        onAction: onAction,
      ),
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
  final ValueChanged<SeriesContextAction> onAction;

  void handleAction(SeriesContextAction action) {
    onAction(action);
    onClose();
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final AppThemeTokens tokens = context.tokens;
    return ContextMenuContainer(
      title: title,
      leadingIcon: LucideIcons.libraryBig,
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            SizedBox(height: tokens.spacing.xs + 2),
            _FluentMenuItem(
              icon: LucideIcons.bookOpen,
              label: '阅读系列',
              shortcut: 'Enter',
              onTap: () => handleAction(SeriesContextAction.read),
            ),
            _FluentMenuItem(
              icon: LucideIcons.arrowUpDown,
              label: '调整顺序',
              onTap: () => handleAction(SeriesContextAction.reorder),
            ),
            _FluentMenuItem(
              icon: LucideIcons.plus,
              label: '添加漫画',
              onTap: () => handleAction(SeriesContextAction.addComics),
            ),
            Divider(height: 14, thickness: 1.4, color: cs.borderMedium),
            _FluentMenuItem(
              icon: LucideIcons.squarePen,
              label: '重命名',
              onTap: () => handleAction(SeriesContextAction.rename),
            ),
            Divider(height: 14, thickness: 1.4, color: cs.borderMedium),
            _FluentMenuItem(
              icon: LucideIcons.trash2,
              label: '删除',
              shortcut: 'Del',
              isDestructive: true,
              onTap: () => handleAction(SeriesContextAction.delete),
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
              ? cs.warning.withAlpha(16)
              : cs.hoverBackground,
          splashFactory: NoSplash.splashFactory,
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: tokens.spacing.sm + 2,
              vertical: tokens.spacing.sm,
            ),
            child: Row(
              children: <Widget>[
                Icon(
                  icon,
                  size: 16,
                  color: isDestructive ? cs.warning : cs.textSecondary,
                ),
                SizedBox(width: tokens.spacing.md),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: tokens.text.bodySm,
                      fontWeight: FontWeight.w500,
                      color: isDestructive ? cs.warning : cs.textPrimary,
                    ),
                  ),
                ),
                if (shortcut != null)
                  Text(
                    shortcut!,
                    style: TextStyle(
                      fontSize: tokens.text.labelXs - 1,
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
