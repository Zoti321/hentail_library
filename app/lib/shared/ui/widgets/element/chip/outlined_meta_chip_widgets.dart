part of 'outlined_meta_chip.dart';

// 内部私有控件（#309 part 拆分）：删除按钮、可交互外壳、外观与标签。
class _OutlinedMetaChipRemoveButton extends StatelessWidget {
  const _OutlinedMetaChipRemoveButton({
    required this.color,
    required this.onRemove,
    this.tooltip,
  });

  final Color color;
  final VoidCallback onRemove;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final Widget button = MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onRemove,
        child: SizedBox(
          width: 16,
          height: 16,
          child: Icon(LucideIcons.x, size: 12, color: color),
        ),
      ),
    );
    if (tooltip == null || tooltip!.isEmpty) {
      return button;
    }
    return Tooltip(message: tooltip!, child: button);
  }
}

class _InteractiveOutlinedMetaChip extends HookWidget {
  const _InteractiveOutlinedMetaChip({
    required this.text,
    required this.borderColor,
    required this.restBackground,
    required this.borderRadius,
    required this.padding,
    required this.showClickCursor,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.onSecondaryTapUp,
  });

  final String text;
  final Color borderColor;
  final Color restBackground;
  final BorderRadius borderRadius;
  final EdgeInsets padding;
  final bool showClickCursor;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final GestureTapUpCallback? onSecondaryTapUp;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final ValueNotifier<bool> isHovered = useState(false);
    final ValueNotifier<bool> isPressed = useState(false);

    final Color hoverFill = cs.surfaceContainer;
    // `Colors.transparent` is black at alpha 0; Color.lerp then flashes dark gray.
    final Color restFill = restBackground.a == 0
        ? hoverFill.withAlpha(0)
        : restBackground;
    final Color hoverStateFill = Color.alphaBlend(
      hoverFill.withAlpha(110),
      restFill,
    );
    final Color pressFill = Color.alphaBlend(
      hoverFill.withAlpha(160),
      restFill,
    );

    return FocusableActionDetector(
      actions: <Type, Action<Intent>>{
        if (onTap != null)
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (ActivateIntent intent) {
              onTap!();
              return null;
            },
          ),
      },
      onShowFocusHighlight: (bool focused) {
        if (!focused && !isHovered.value) {
          isPressed.value = false;
        }
      },
      onShowHoverHighlight: (bool hovered) {
        isHovered.value = hovered;
        if (!hovered) {
          isPressed.value = false;
        }
      },
      child: Builder(
        builder: (BuildContext context) {
          final bool focused = Focus.of(context).hasFocus;
          final Color focusedFill = Color.alphaBlend(
            hoverFill.withAlpha(80),
            restFill,
          );
          final Color resolvedBackground = isPressed.value
              ? pressFill
              : isHovered.value || focused
              ? (isHovered.value ? hoverStateFill : focusedFill)
              : restFill;
          return Semantics(
            button: true,
            label: text,
            child: MouseRegion(
              cursor: showClickCursor
                  ? SystemMouseCursors.click
                  : MouseCursor.defer,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTapDown: onTap == null ? null : (_) => isPressed.value = true,
                onTapUp: onTap == null ? null : (_) => isPressed.value = false,
                onTapCancel: onTap == null
                    ? null
                    : () => isPressed.value = false,
                onTap: onTap,
                onLongPress: onLongPress,
                onSecondaryTapUp: onSecondaryTapUp,
                child: _OutlinedMetaChipChrome(
                  backgroundColor: resolvedBackground,
                  borderColor: borderColor,
                  borderRadius: borderRadius,
                  padding: padding,
                  animate: true,
                  child: child,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _OutlinedMetaChipChrome extends StatelessWidget {
  const _OutlinedMetaChipChrome({
    required this.backgroundColor,
    required this.borderColor,
    required this.borderRadius,
    required this.padding,
    required this.child,
    this.animate = false,
  });

  final Color backgroundColor;
  final Color borderColor;
  final BorderRadius borderRadius;
  final EdgeInsets padding;
  final Widget child;
  final bool animate;

  @override
  Widget build(BuildContext context) {
    final BoxDecoration decoration = BoxDecoration(
      color: backgroundColor,
      borderRadius: borderRadius,
      border: borderColor.a == 0 ? null : Border.all(color: borderColor),
    );
    if (!animate) {
      return Container(padding: padding, decoration: decoration, child: child);
    }
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutCubic,
      padding: padding,
      decoration: decoration,
      child: child,
    );
  }
}

class _OutlinedMetaChipLabel extends StatelessWidget {
  const _OutlinedMetaChipLabel({
    required this.text,
    required this.color,
    this.verified = false,
    this.icon,
    this.count,
  });

  final String text;
  final Color color;
  final bool verified;
  final IconData? icon;
  final int? count;

  @override
  Widget build(BuildContext context) {
    final AppThemeTokens tokens = context.tokens;
    final ColorScheme cs = Theme.of(context).colorScheme;
    final Text label = Text(
      text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        fontSize: tokens.text.labelXs,
        height: 1.2,
        color: color,
        fontWeight: FontWeight.w500,
      ),
    );
    if (!verified && icon == null && count == null) {
      return label;
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        if (icon != null) ...<Widget>[
          Icon(icon, size: 12, color: color),
          SizedBox(width: tokens.spacing.xs),
        ],
        Flexible(child: label),
        if (count != null) ...<Widget>[
          SizedBox(width: tokens.spacing.xs),
          Text(
            '$count',
            maxLines: 1,
            style: TextStyle(
              fontSize: tokens.text.labelXs,
              height: 1.2,
              color: context.hentai.textTertiary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
        if (verified) ...<Widget>[
          SizedBox(width: tokens.spacing.xs),
          Icon(LucideIcons.badgeCheck, size: 12, color: cs.primary),
        ],
      ],
    );
  }
}
