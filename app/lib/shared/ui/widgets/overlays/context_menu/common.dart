import 'package:flutter/material.dart';

import 'package:hentai_library/design-system/design_system.dart';
import 'package:hentai_library/shared/ui/widgets/actions/popup_menu_panel_shell.dart';

export 'package:hentai_library/shared/ui/widgets/overlays/context_menu/context_menu_action_item.dart';

typedef ContextMenuBuilder = Widget Function(VoidCallback onClose);

class ContextMenuCommon {
  /// Shows a context menu with its top-left at [position].
  ///
  /// [position] must be in **global** coordinates (e.g. [TapUpDetails.globalPosition]).
  /// It is converted into the [Overlay]'s local space so ShellRoute + in-app
  /// title bar insets do not shift the menu (reader non-fullscreen case).
  static void show(
    BuildContext context, {
    required Offset position,
    required double width,
    required double height,
    required ContextMenuBuilder builder,
  }) {
    final OverlayState overlay = Overlay.of(context);
    final RenderBox overlayBox =
        overlay.context.findRenderObject()! as RenderBox;
    final Offset local = overlayBox.globalToLocal(position);
    final Size overlaySize = overlayBox.size;
    late OverlayEntry entry;
    double left = local.dx;
    double top = local.dy;
    if (left + width > overlaySize.width) {
      left = overlaySize.width - width - 10;
    }
    if (top + height > overlaySize.height) {
      top = overlaySize.height - height - 10;
    }
    if (left < 0) {
      left = 0;
    }
    if (top < 0) {
      top = 0;
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
    this.title,
    required this.child,
    this.width = 236,
  });

  /// When null, the title header row is omitted.
  final String? title;
  final Widget child;
  final double width;

  @override
  Widget build(BuildContext context) {
    final AppThemeTokens tokens = context.tokens;
    final String? title = this.title;
    return PopupMenuPanelShell(
      width: width,
      blurRadius: 6,
      shadowOffset: const Offset(0, 4),
      borderRadius: tokens.radius.xs,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (title != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
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
