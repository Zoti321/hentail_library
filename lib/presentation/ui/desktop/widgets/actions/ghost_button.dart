import 'package:flutter/material.dart';

enum _GhostButtonVariant { icon, iconText }

class GhostButton extends StatelessWidget {
  const GhostButton.icon({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.semanticLabel,
    this.iconSize = 16,
    this.size = 32,
    this.borderRadius = 8,
    this.foregroundColor,
    this.hoverColor,
    this.overlayColor,
    this.delayTooltipThreeSeconds = true,
  }) : text = null,
       padding = EdgeInsets.zero,
       _variant = _GhostButtonVariant.icon;
  const GhostButton.iconText({
    super.key,
    required this.icon,
    required this.text,
    required this.onPressed,
    this.tooltip,
    this.semanticLabel,
    this.iconSize = 16,
    this.padding = const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    this.borderRadius = 8,
    this.foregroundColor,
    this.hoverColor,
    this.overlayColor,
    this.delayTooltipThreeSeconds = true,
  }) : size = 32,
       _variant = _GhostButtonVariant.iconText;

  final IconData icon;
  final String? text;
  final String? tooltip;
  final VoidCallback? onPressed;
  final String? semanticLabel;
  final double iconSize;
  final double size;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final Color? foregroundColor;
  final Color? hoverColor;
  final Color? overlayColor;
  final bool delayTooltipThreeSeconds;
  final _GhostButtonVariant _variant;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final bool isEnabled = onPressed != null;
    final String effectiveTooltip = tooltip ?? text ?? '';
    final String semanticsText = semanticLabel ?? effectiveTooltip;
    final Color enabledForeground = foregroundColor ?? cs.onSurfaceVariant;
    final Color disabledForeground = enabledForeground.withAlpha(96);
    final Color effectiveHoverColor = hoverColor ?? cs.surfaceContainer;
    final Color effectiveOverlayColor =
        overlayColor ?? effectiveHoverColor.withAlpha(110);
    final Widget button = _variant == _GhostButtonVariant.icon
        ? IconButton(
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
                  ? enabledForeground
                  : disabledForeground,
              backgroundColor: Colors.transparent,
              disabledBackgroundColor: Colors.transparent,
              hoverColor: effectiveHoverColor,
              highlightColor: effectiveHoverColor,
              overlayColor: effectiveOverlayColor,
              splashFactory: NoSplash.splashFactory,
            ),
            icon: Icon(icon),
          )
        : TextButton.icon(
            onPressed: onPressed,
            icon: Icon(icon, size: iconSize),
            label: Text(
              text!,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
            style: ButtonStyle(
              foregroundColor: WidgetStateProperty.resolveWith<Color>((states) {
                if (states.contains(WidgetState.disabled)) {
                  return disabledForeground;
                }
                return enabledForeground;
              }),
              backgroundColor: WidgetStateProperty.resolveWith<Color>((states) {
                if (states.contains(WidgetState.hovered)) {
                  return effectiveHoverColor;
                }
                return Colors.transparent;
              }),
              overlayColor: WidgetStateProperty.all(effectiveOverlayColor),
              shape: WidgetStateProperty.all(
                RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(borderRadius),
                ),
              ),
              padding: WidgetStateProperty.all(padding),
            ),
          );
    final Widget withTooltip = effectiveTooltip.isEmpty
        ? button
        : Tooltip(
            message: effectiveTooltip,
            waitDuration: delayTooltipThreeSeconds
                ? const Duration(seconds: 3)
                : null,
            showDuration: const Duration(seconds: 2),
            child: button,
          );
    return Semantics(
      button: true,
      enabled: isEnabled,
      label: semanticsText,
      child: withTooltip,
    );
  }
}
