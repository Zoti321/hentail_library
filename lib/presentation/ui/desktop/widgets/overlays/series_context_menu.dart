import 'package:flutter/material.dart';
import 'package:hentai_library/theme/theme.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

enum SeriesContextAction { read, reorder, addComics, rename, delete }

class SeriesContextMenu {
  static void show(
    BuildContext context, {
    required Offset position,
    required String seriesName,
    required ValueChanged<SeriesContextAction> onAction,
  }) {
    final OverlayState overlay = Overlay.of(context);
    late OverlayEntry entry;
    final Size screenSize = MediaQuery.of(context).size;
    double left = position.dx;
    double top = position.dy;
    const double width = 236;
    const double height = 286;
    if (left + width > screenSize.width) {
      left = screenSize.width - width - 10;
    }
    if (top + height > screenSize.height) {
      top = screenSize.height - height - 10;
    }
    entry = OverlayEntry(
      builder: (BuildContext context) => Stack(
        children: <Widget>[
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
                title: seriesName,
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
  final ValueChanged<SeriesContextAction> onAction;

  void handleAction(SeriesContextAction action) {
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
        boxShadow: <BoxShadow>[
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
          children: <Widget>[
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
                children: <Widget>[
                  Icon(
                    LucideIcons.libraryBig,
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
            Divider(height: 10, thickness: 1, color: cs.borderSubtle),
            _MenuGroupLabel(label: '管理', color: cs.textSecondary),
            _FluentMenuItem(
              icon: LucideIcons.squarePen,
              label: '重命名',
              onTap: () => handleAction(SeriesContextAction.rename),
            ),
            Divider(height: 10, thickness: 1, color: cs.borderSubtle),
            _MenuGroupLabel(label: '危险操作', color: cs.warning),
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
