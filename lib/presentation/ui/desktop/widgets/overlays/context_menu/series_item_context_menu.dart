import 'package:flutter/material.dart';
import 'package:hentai_library/presentation/theme/theme.dart';
import 'package:hentai_library/presentation/ui/desktop/widgets/overlays/context_menu/common.dart';
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
    final AppThemeTokens tokens = context.tokens;
    return ContextMenuContainer(
      title: title,
      leadingIcon: LucideIcons.panelRightOpen,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          SizedBox(height: tokens.spacing.xs + 2),
          _FluentMenuItem(
            icon: LucideIcons.info,
            label: '跳转到详情页',
            onTap: () => handleAction(SeriesItemContextAction.goToDetail),
          ),
          _FluentMenuItem(
            icon: LucideIcons.externalLink,
            label: '在文件资源管理器中显示',
            onTap: () => handleAction(SeriesItemContextAction.showInExplorer),
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
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

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
          hoverColor: cs.hentai.hoverBackground,
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
                  color: cs.hentai.textSecondary,
                ),
                SizedBox(width: tokens.spacing.md),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: tokens.text.bodySm,
                      fontWeight: FontWeight.w500,
                      color: cs.hentai.textPrimary,
                    ),
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
