import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hentai_library/shared/ui/theme/theme.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// 描边胶囊 chip，用于详情页作者/标签等元数据展示。
///
/// 传入 [onTap] 时变为可点：click 光标、Semantics button、hover/press 铺底
///（对齐 [GhostButton]：`surfaceContainer` + `withAlpha(110)` overlay）。
///
/// 传入 [onRemove] 时在文案右侧渲染移除按钮（表单多选字段）。
class OutlinedMetaChip extends HookWidget {
  const OutlinedMetaChip({
    super.key,
    required this.text,
    this.borderColor,
    this.backgroundColor,
    this.textColor,
    this.compact = false,
    this.verified = false,
    this.icon,
    this.count,
    this.onTap,
    this.onLongPress,
    this.onSecondaryTapUp,
    this.onRemove,
    this.removeTooltip,
    this.removeOnDesktopHoverOnly = false,
    this.showBorder = true,
  });

  final String text;
  final Color? borderColor;
  final Color? backgroundColor;
  final Color? textColor;

  /// 为 true 时使用更紧的 padding（`10×4`，对齐 [R18RatingChip]）。
  final bool compact;
  final bool verified;
  final IconData? icon;

  /// Named facet attachment count, rendered to the right of [text].
  final int? count;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final GestureTapUpCallback? onSecondaryTapUp;
  final VoidCallback? onRemove;
  final String? removeTooltip;

  /// 桌面（Windows / macOS / Linux）仅在 hover 时露出移除按钮；移动端始终露出。
  ///
  /// 无论是否露出，有 [onRemove] 时都会预留按钮占位，避免 hover 改变 chip 尺寸。
  final bool removeOnDesktopHoverOnly;

  /// 为 false 时去掉描边与实心底，用 [textColor] 与背景区分（外链等轻量操作）。
  final bool showBorder;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final AppThemeTokens tokens = context.tokens;
    final BorderRadius borderRadius = BorderRadius.circular(tokens.radius.pill);
    final Color effectiveBorder = showBorder
        ? (borderColor ?? cs.hentai.borderSubtle)
        : Colors.transparent;
    final Color restBackground =
        backgroundColor ?? (showBorder ? cs.surface : Colors.transparent);
    final Color effectiveTextColor = textColor ?? cs.hentai.textSecondary;
    final EdgeInsets padding = compact
        ? const EdgeInsets.symmetric(horizontal: 10, vertical: 4)
        : const EdgeInsets.symmetric(horizontal: 12, vertical: 6);

    final Widget label = _OutlinedMetaChipLabel(
      text: text,
      color: effectiveTextColor,
      verified: verified,
      icon: icon,
      count: count,
    );
    final ValueNotifier<bool> isHovered = useState(false);
    final bool desktop = switch (Theme.of(context).platform) {
      TargetPlatform.windows ||
      TargetPlatform.linux ||
      TargetPlatform.macOS => true,
      TargetPlatform.android ||
      TargetPlatform.iOS ||
      TargetPlatform.fuchsia => false,
    };
    final bool revealRemove =
        onRemove != null &&
        (!removeOnDesktopHoverOnly || !desktop || isHovered.value);
    final Widget content = onRemove == null
        ? label
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(child: label),
              SizedBox(width: tokens.spacing.xs),
              Visibility(
                visible: revealRemove,
                maintainSize: true,
                maintainAnimation: true,
                maintainState: true,
                child: _OutlinedMetaChipRemoveButton(
                  color: effectiveTextColor,
                  tooltip: removeTooltip,
                  onRemove: onRemove!,
                ),
              ),
            ],
          );

    final String semanticsLabel = count == null ? text : '$text $count';
    final bool interactive =
        onTap != null || onLongPress != null || onSecondaryTapUp != null;
    final Widget chip = interactive
        ? _InteractiveOutlinedMetaChip(
            text: semanticsLabel,
            borderColor: effectiveBorder,
            restBackground: restBackground,
            borderRadius: borderRadius,
            padding: padding,
            showClickCursor: onTap != null,
            onTap: onTap,
            onLongPress: onLongPress,
            onSecondaryTapUp: onSecondaryTapUp,
            child: content,
          )
        : Semantics(
            label: semanticsLabel,
            child: _OutlinedMetaChipChrome(
              backgroundColor: restBackground,
              borderColor: effectiveBorder,
              borderRadius: borderRadius,
              padding: padding,
              child: content,
            ),
          );
    if (!removeOnDesktopHoverOnly || !desktop) {
      return chip;
    }
    return MouseRegion(
      onEnter: (_) => isHovered.value = true,
      onExit: (_) => isHovered.value = false,
      child: chip,
    );
  }
}

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
              color: cs.hentai.textTertiary,
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
