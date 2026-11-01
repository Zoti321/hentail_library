import 'package:flutter/material.dart';
import 'package:hentai_library/shared/ui/widgets/desktop/desktop_title_bar_metrics.dart';
import 'package:hentai_library/shared/ui/widgets/desktop/desktop_window_controls.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:window_manager/window_manager.dart';

/// Desktop window title strip: optional ☰ menu (left) + window controls (right).
///
/// No global search (removed); the empty middle is a window drag area.
/// When [showNavigationMenu] is true (drawer shell), ☰ opens app navigation.
class Md3eDesktopTitleBar extends StatelessWidget {
  const Md3eDesktopTitleBar({
    super.key,
    this.showWindowControls = true,
    this.showNavigationMenu = false,
    this.onNavigationMenuPressed,
    this.onWindowMinimize,
    this.onWindowMaximize,
    this.onWindowClose,
    this.backgroundColor,
  });

  final bool showWindowControls;
  final bool showNavigationMenu;
  final VoidCallback? onNavigationMenuPressed;
  final VoidCallback? onWindowMinimize;
  final VoidCallback? onWindowMaximize;
  final VoidCallback? onWindowClose;

  /// Defaults to [M3EColorScheme.surfaceContainerLow] (lab chrome).
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    final M3EColorScheme scheme = M3ETheme.of(context).colorScheme;

    return SizedBox(
      height: Md3eDesktopTitleBarMetrics.height,
      width: double.infinity,
      child: ColoredBox(
        color: backgroundColor ?? scheme.surfaceContainerLow,
        child: Stack(
          children: <Widget>[
            // Bottom layer: empty title-bar area drags the window; buttons above
            // (menu, window controls) receive their own taps.
            const Positioned.fill(
              child: DragToMoveArea(child: SizedBox.expand()),
            ),
            Positioned.fill(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  if (showNavigationMenu)
                    SizedBox(
                      width: Md3eDesktopTitleBarMetrics.navigationMenuWidth,
                      height: Md3eDesktopTitleBarMetrics.height,
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
                    Md3eDesktopWindowControls(
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
