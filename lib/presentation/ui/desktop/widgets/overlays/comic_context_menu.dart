import 'package:flutter/material.dart';
import 'package:hentai_library/theme/theme.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

enum ComicContextAction { read, detail, edit, showInExplorer, delete }

class ComicContextMenu {
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
    final AppThemeTokens tokens = context.tokens;
    final double panelRadius = tokens.radius.lg + 2;
    return Container(
      width: 236,
      decoration: BoxDecoration(
        color: cs.winSurface,
        borderRadius: BorderRadius.circular(panelRadius),
        border: Border.all(color: cs.borderMedium),
        boxShadow: [
          BoxShadow(
            color: cs.cardShadow,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(panelRadius),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(
                horizontal: tokens.spacing.md,
                vertical: tokens.spacing.sm + 2,
              ),
              decoration: BoxDecoration(
                color: cs.surfaceContainer,
                border: Border(bottom: BorderSide(color: cs.borderSubtle)),
              ),
              child: Row(
                children: [
                  Icon(
                    LucideIcons.panelRightOpen,
                    size: 14,
                    color: cs.iconSecondary,
                  ),
                  SizedBox(width: tokens.spacing.xs + 2),
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: tokens.text.labelXs,
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
            SizedBox(height: tokens.spacing.xs + 2),
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
            Divider(height: 10, thickness: 1, color: cs.borderSubtle),
            _MenuGroupLabel(label: '管理', color: cs.textSecondary),
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
            Divider(height: 10, thickness: 1, color: cs.borderSubtle),
            _MenuGroupLabel(label: '危险操作', color: cs.warning),
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
    final AppThemeTokens tokens = context.tokens;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        tokens.spacing.md,
        0,
        tokens.spacing.md,
        tokens.spacing.xs,
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: tokens.text.labelXs - 1,
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
              children: [
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
