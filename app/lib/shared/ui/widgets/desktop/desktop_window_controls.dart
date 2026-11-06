import 'package:flutter/material.dart';
import 'package:hentai_library/shared/ui/widgets/desktop/desktop_title_bar_metrics.dart';
import 'package:hentai_library/shared/ui/widgets/desktop/window_manager_bindings.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

/// Windows-style minimize / maximize / close cluster (MASTER `WindowButton` set).
class DesktopWindowControls extends StatelessWidget {
  const DesktopWindowControls({
    super.key,
    this.onMinimize,
    this.onMaximize,
    this.onClose,
  });

  final VoidCallback? onMinimize;
  final VoidCallback? onMaximize;
  final VoidCallback? onClose;

  static const Size _buttonVisual = Size(
    DesktopTitleBarMetrics.windowButtonSize,
    DesktopTitleBarMetrics.windowButtonSize,
  );

  @override
  Widget build(BuildContext context) {
    final M3EColorScheme scheme = M3ETheme.of(context).colorScheme;

    return SizedBox(
      width: DesktopTitleBarMetrics.windowControlsWidth,
      height: DesktopTitleBarMetrics.windowButtonSize,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: <Widget>[
          _WindowControlButton(
            icon: Icons.remove,
            tooltip: '最小化',
            onPressed: onMinimize ?? windowManagerMinimize,
          ),
          _WindowControlButton(
            icon: Icons.crop_square,
            tooltip: '最大化',
            onPressed: onMaximize ?? windowManagerToggleMaximize,
          ),
          _WindowControlButton(
            icon: Icons.close,
            tooltip: '关闭',
            onPressed: onClose ?? windowManagerClose,
            decoration: CloseWindowButtonDecoration(scheme),
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
M3EIconButtonDecoration CloseWindowButtonDecoration(
  M3EColorScheme scheme,
) {
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

class _WindowControlButton extends StatelessWidget {
  const _WindowControlButton({
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
      icon: Icon(icon, size: DesktopTitleBarMetrics.windowButtonIconSize),
      tooltip: tooltip,
      onPressed: onPressed,
      variant: M3EIconButtonVariant.standard,
      size: M3EIconButtonSize.sm,
      visualSize: DesktopWindowControls._buttonVisual,
      inflateHitTarget: false,
      decoration: decoration,
    );
  }
}
