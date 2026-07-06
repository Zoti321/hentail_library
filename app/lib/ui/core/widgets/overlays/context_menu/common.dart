import 'package:flutter/material.dart';
import 'package:hentai_library/ui/core/theme/theme.dart';
import 'package:hentai_library/ui/core/widgets/actions/popup_menu_panel_shell.dart';

typedef ContextMenuBuilder = Widget Function(VoidCallback onClose);

class ContextMenuCommon {
  static void show(
    BuildContext context, {
    required Offset position,
    required double width,
    required double height,
    required ContextMenuBuilder builder,
  }) {
    final OverlayState overlay = Overlay.of(context);
    late OverlayEntry entry;
    final Size screenSize = MediaQuery.of(context).size;
    double left = position.dx;
    double top = position.dy;
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
              child: builder(() => entry.remove()),
            ),
          ),
        ],
      ),
    );
    overlay.insert(entry);
  }
}

class ContextMenuContainer extends StatelessWidget {
  const ContextMenuContainer({
    super.key,
    required this.title,
    required this.child,
    this.width = 236,
  });

  final String title;
  final Widget child;
  final double width;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final AppThemeTokens tokens = context.tokens;
    return PopupMenuPanelShell(
      width: width,
      blurRadius: 6,
      shadowOffset: const Offset(0, 4),
      borderRadius: tokens.radius.xs,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
            child: Text(
              title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: cs.hentai.textPrimary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          child,
        ],
      ),
    );
  }
}

class ContextMenuActionItem extends StatelessWidget {
  const ContextMenuActionItem({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.isDestructive = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isDestructive;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final HentaiColorScheme palette = cs.hentai;
    final Color hoverColor = isDestructive
        ? palette.contextMenuDanger.withAlpha(26)
        : cs.primary.withAlpha(10);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        hoverColor: hoverColor,
        splashColor: hoverColor,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: <Widget>[
              Icon(icon, size: 16, color: palette.iconDefault),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: palette.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
