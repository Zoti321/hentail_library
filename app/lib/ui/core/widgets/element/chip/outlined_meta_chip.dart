import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hentai_library/ui/core/theme/theme.dart';
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
    this.textColor,
    this.compact = false,
    this.verified = false,
    this.icon,
    this.onTap,
    this.onLongPress,
    this.onRemove,
    this.removeTooltip,
    this.removeOnDesktopHoverOnly = false,
  });

  final String text;
  final Color? borderColor;
  final Color? textColor;

  /// 为 true 时使用更紧的 padding（`10×4`，对齐 [R18RatingChip]）。
  final bool compact;
  final bool verified;
  final IconData? icon;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onRemove;
  final String? removeTooltip;

  /// 桌面（Windows / macOS / Linux）仅在 hover 时渲染移除按钮；移动端始终渲染。
  final bool removeOnDesktopHoverOnly;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final AppThemeTokens tokens = context.tokens;
    final BorderRadius borderRadius = BorderRadius.circular(tokens.radius.pill);
    final Color effectiveBorder = borderColor ?? cs.hentai.borderSubtle;
    final Color effectiveTextColor = textColor ?? cs.hentai.textSecondary;
    final EdgeInsets padding = compact
        ? const EdgeInsets.symmetric(horizontal: 10, vertical: 4)
        : const EdgeInsets.symmetric(horizontal: 12, vertical: 6);

    final Widget label = _OutlinedMetaChipLabel(
      text: text,
      color: effectiveTextColor,
      verified: verified,
      icon: icon,
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
    final bool showRemove =
        onRemove != null &&
        (!removeOnDesktopHoverOnly || !desktop || isHovered.value);
    final Widget content = showRemove
        ? Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(child: label),
              SizedBox(width: tokens.spacing.xs),
              _OutlinedMetaChipRemoveButton(
                color: effectiveTextColor,
                tooltip: removeTooltip,
                onRemove: onRemove!,
              ),
            ],
          )
        : label;

    final Widget chip = (onTap == null && onLongPress == null)
        ? Semantics(
            label: text,
            child: _OutlinedMetaChipChrome(
              backgroundColor: cs.surface,
              borderColor: effectiveBorder,
              borderRadius: borderRadius,
              padding: padding,
              child: content,
            ),
          )
        : _InteractiveOutlinedMetaChip(
            text: text,
            borderColor: effectiveBorder,
            borderRadius: borderRadius,
            padding: padding,
            onTap: onTap,
            onLongPress: onLongPress,
            child: content,
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
    return SizedBox(
      width: 16,
      height: 16,
      child: IconButton(
        tooltip: tooltip ?? '',
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints.tightFor(width: 16, height: 16),
        visualDensity: VisualDensity.compact,
        splashRadius: 10,
        onPressed: onRemove,
        icon: Icon(Icons.close, size: 12, color: color),
      ),
    );
  }
}

class _InteractiveOutlinedMetaChip extends HookWidget {
  const _InteractiveOutlinedMetaChip({
    required this.text,
    required this.borderColor,
    required this.borderRadius,
    required this.padding,
    required this.child,
    this.onTap,
    this.onLongPress,
  });

  final String text;
  final Color borderColor;
  final BorderRadius borderRadius;
  final EdgeInsets padding;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final ValueNotifier<bool> isHovered = useState(false);
    final ValueNotifier<bool> isPressed = useState(false);

    final Color hoverFill = cs.surfaceContainer;
    final Color pressFill = Color.alphaBlend(
      hoverFill.withAlpha(110),
      hoverFill,
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
            cs.surface,
          );
          final Color resolvedBackground = isPressed.value
              ? pressFill
              : isHovered.value || focused
              ? (isHovered.value ? hoverFill : focusedFill)
              : cs.surface;
          return Semantics(
            button: true,
            label: text,
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTapDown: onTap == null ? null : (_) => isPressed.value = true,
                onTapUp: onTap == null ? null : (_) => isPressed.value = false,
                onTapCancel: onTap == null
                    ? null
                    : () => isPressed.value = false,
                onTap: onTap,
                onLongPress: onLongPress,
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
      border: Border.all(color: borderColor),
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
  });

  final String text;
  final Color color;
  final bool verified;
  final IconData? icon;

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
    if (!verified && icon == null) {
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
        if (verified) ...<Widget>[
          SizedBox(width: tokens.spacing.xs),
          Icon(LucideIcons.badgeCheck, size: 12, color: cs.primary),
        ],
      ],
    );
  }
}
