import 'package:flutter/material.dart';
import 'package:hentai_library/md3e/widgets/md3e_desktop_title_bar_metrics.dart';
import 'package:hentai_library/md3e/widgets/md3e_window_manager_bindings.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart'
    show WidgetState, WidgetStateProperty;

/// Windows-style minimize / maximize / close cluster (MASTER `WindowButton` set).
class Md3eDesktopWindowControls extends StatelessWidget {
  const Md3eDesktopWindowControls({
    super.key,
    this.onMinimize,
    this.onMaximize,
    this.onClose,
  });

  final VoidCallback? onMinimize;
  final VoidCallback? onMaximize;
  final VoidCallback? onClose;

  static const Size _buttonVisual = Size(
    Md3eDesktopTitleBarMetrics.windowButtonSize,
    Md3eDesktopTitleBarMetrics.windowButtonSize,
  );

  @override
  Widget build(BuildContext context) {
    final M3EColorScheme scheme = M3ETheme.of(context).colorScheme;

    return SizedBox(
      width: Md3eDesktopTitleBarMetrics.windowControlsWidth,
      height: Md3eDesktopTitleBarMetrics.windowButtonSize,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: <Widget>[
          _Md3eWindowControlButton(
            icon: Icons.remove,
            tooltip: '最小化',
            onPressed: onMinimize ?? md3eWindowManagerMinimize,
          ),
          _Md3eWindowControlButton(
            icon: Icons.crop_square,
            tooltip: '最大化',
            onPressed: onMaximize ?? md3eWindowManagerToggleMaximize,
          ),
          _Md3eWindowControlButton(
            icon: Icons.close,
            tooltip: '关闭',
            onPressed: onClose ?? md3eWindowManagerClose,
            decoration: _md3eCloseWindowButtonDecoration(scheme),
          ),
        ],
      ),
    );
  }
}

/// Close control hover/press via [M3EIconButtonDecoration.overlayColor].
///
/// `backgroundColor` / `foregroundColor` on the decoration are resolved once
/// without hover states in M3E 1.2 — only `overlayColor` is state-aware.
M3EIconButtonDecoration _md3eCloseWindowButtonDecoration(M3EColorScheme scheme) {
  return M3EIconButtonDecoration(
    overlayColor: WidgetStateProperty.resolveWith((Set<WidgetState> states) {
      if (states.contains(WidgetState.disabled)) {
        return null;
      }
      final Set<WidgetState> interaction = Set<WidgetState>.of(states)
        ..remove(WidgetState.focused);
      if (interaction.contains(WidgetState.pressed)) {
        return scheme.error;
      }
      if (interaction.contains(WidgetState.hovered)) {
        return scheme.errorContainer;
      }
      return null;
    }),
  );
}

class _Md3eWindowControlButton extends StatelessWidget {
  const _Md3eWindowControlButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.decoration,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  final M3EIconButtonDecoration? decoration;

  @override
  Widget build(BuildContext context) {
    return M3EIconButton(
      icon: Icon(icon, size: Md3eDesktopTitleBarMetrics.windowButtonIconSize),
      tooltip: tooltip,
      onPressed: onPressed,
      variant: M3EIconButtonVariant.standard,
      size: M3EIconButtonSize.sm,
      visualSize: Md3eDesktopWindowControls._buttonVisual,
      inflateHitTarget: false,
      decoration: decoration,
    );
  }
}
