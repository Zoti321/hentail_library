import 'package:flutter/material.dart';
import 'package:hentai_library/presentation/theme/theme.dart';

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
    required this.leadingIcon,
    required this.child,
    this.width = 236,
  });

  final String title;
  final IconData leadingIcon;
  final Widget child;
  final double width;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final AppThemeTokens tokens = context.tokens;
    final HentaiColorScheme palette = cs.hentai;
    final double panelRadius = tokens.radius.md + 2;
    return Container(
      width: width,
      decoration: BoxDecoration(
        color: palette.contextMenuBackground,
        borderRadius: BorderRadius.circular(panelRadius),
        border: Border.all(color: palette.contextMenuBorder),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: palette.contextMenuShadow,
            blurRadius: 20,
            spreadRadius: -4,
            offset: const Offset(0, 8),
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
                horizontal: tokens.spacing.md + 2,
                vertical: tokens.spacing.sm + 1,
              ),
              decoration: BoxDecoration(
                color: palette.contextMenuBackground,
                border: Border(
                  bottom: BorderSide(color: palette.contextMenuSeparator),
                ),
              ),
              child: Row(
                children: <Widget>[
                  Icon(
                    leadingIcon,
                    size: 14,
                    color: palette.contextMenuMutedText,
                  ),
                  SizedBox(width: tokens.spacing.xs + 2),
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: tokens.text.bodySm,
                        fontWeight: FontWeight.w600,
                        color: palette.contextMenuText,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            child,
          ],
        ),
      ),
    );
  }
}

class ContextMenuDivider extends StatelessWidget {
  const ContextMenuDivider({super.key});
  @override
  Widget build(BuildContext context) {
    final AppThemeTokens tokens = context.tokens;
    final HentaiColorScheme palette = Theme.of(context).colorScheme.hentai;
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: tokens.spacing.xs + 1,
        vertical: tokens.spacing.xs + 1,
      ),
      child: Container(
        width: double.infinity,
        height: 1,
        color: palette.contextMenuSeparator,
      ),
    );
  }
}
