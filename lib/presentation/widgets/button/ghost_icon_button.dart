import 'package:flutter/material.dart';

class GhostIconButton extends StatelessWidget {
  const GhostIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.semanticLabel,
    this.size = 32,
    this.iconSize = 16,
    this.borderRadius = 8,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final String? semanticLabel;
  final double size;
  final double iconSize;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme cs = theme.colorScheme;
    final bool isEnabled = onPressed != null;
    final String label = semanticLabel ?? tooltip;

    return Semantics(
      button: true,
      enabled: isEnabled,
      label: label,
      child: Tooltip(
        message: tooltip,
        child: IconButton(
          onPressed: onPressed,
          iconSize: iconSize,
          style: IconButton.styleFrom(
            minimumSize: Size.square(size),
            fixedSize: Size.square(size),
            padding: EdgeInsets.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(borderRadius),
            ),
            foregroundColor: isEnabled
                ? cs.onSurfaceVariant
                : cs.onSurface.withOpacity(0.38),
            backgroundColor: Colors.transparent,
            disabledBackgroundColor: Colors.transparent,
            hoverColor: cs.surfaceContainer,
            highlightColor: cs.surfaceContainer,
            splashFactory: NoSplash.splashFactory,
          ),
          icon: Icon(icon),
        ),
      ),
    );
  }
}
