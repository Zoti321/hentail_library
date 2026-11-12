import 'package:flutter/material.dart';

import 'desktop_title_bar_metrics.dart';
import 'desktop_window_actions.dart';
import 'desktop_window_controls.dart';
import '../../theme/color/desktop_shell_surfaces.dart';

import 'package:material_3_expressive/material_3_expressive.dart';

/// Desktop window title strip: optional ☰ menu (left) + window controls (right).
///
/// No global search (removed); the empty middle is a window drag area.
/// When [showNavigationMenu] is true, ☰ invokes [onNavigationMenuPressed].
class DesktopTitleBar extends StatelessWidget {
  const DesktopTitleBar({
    super.key,
    this.showWindowControls = true,
    this.showNavigationMenu = false,
    this.onNavigationMenuPressed,
    this.onWindowMinimize,
    this.onWindowMaximize,
    this.onWindowClose,
    this.onStartDragging,
    this.backgroundColor,
  });

  final bool showWindowControls;
  final bool showNavigationMenu;
  final VoidCallback? onNavigationMenuPressed;
  final VoidCallback? onWindowMinimize;
  final VoidCallback? onWindowMaximize;
  final VoidCallback? onWindowClose;
  final VoidCallback? onStartDragging;

  /// Defaults to [labBrowseCanvasColor] (`surface`).
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    final M3EColorScheme scheme = M3ETheme.of(context).colorScheme;

    final actions = DesktopWindowActions.maybeOf(context);
    return SizedBox(
      height: DesktopTitleBarMetrics.height,
      width: double.infinity,
      child: ColoredBox(
        color: backgroundColor ?? labBrowseCanvasColor(scheme),
        child: Stack(
          children: <Widget>[
            // Bottom layer: empty title-bar area drags the window; buttons above
            // (menu, window controls) receive their own taps.
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onPanStart:
                    (onStartDragging ?? actions?.onStartDragging) == null
                    ? null
                    : (_) => (onStartDragging ?? actions!.onStartDragging)(),
                onDoubleTap: onWindowMaximize ?? actions?.onToggleMaximize,
                child: const SizedBox.expand(),
              ),
            ),
            Positioned.fill(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  if (showNavigationMenu)
                    SizedBox(
                      width: DesktopTitleBarMetrics.navigationMenuWidth,
                      height: DesktopTitleBarMetrics.height,
                      child: Center(
                        child: M3EIconButton(
                          icon: const Icon(Icons.menu),
                          onPressed: onNavigationMenuPressed,
                          variant: M3EIconButtonVariant.standard,
                          size: M3EIconButtonSize.md,
                        ),
                      ),
                    ),
                  const Spacer(),
                  if (showWindowControls)
                    DesktopWindowControls(
                      onMinimize: onWindowMinimize,
                      onMaximize: onWindowMaximize,
                      onClose: onWindowClose,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
