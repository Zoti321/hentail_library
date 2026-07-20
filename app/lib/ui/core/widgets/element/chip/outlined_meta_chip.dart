import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hentai_library/ui/core/theme/theme.dart';

/// 描边胶囊 chip，用于详情页作者/标签等元数据展示。
///
/// 传入 [onTap] 时变为可点：click 光标、Semantics button、hover/press 铺底
///（对齐 [GhostButton]：`surfaceContainer` + `withAlpha(110)` overlay）。
///
/// 传入 [onRemove] 时在文案右侧渲染移除按钮（表单多选字段）。
class OutlinedMetaChip extends StatelessWidget {
  const OutlinedMetaChip({
    super.key,
    required this.text,
    this.borderColor,
    this.textColor,
    this.onTap,
    this.onRemove,
  });

  final String text;
  final Color? borderColor;
  final Color? textColor;
  final VoidCallback? onTap;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final AppThemeTokens tokens = context.tokens;
    final BorderRadius borderRadius = BorderRadius.circular(tokens.radius.pill);
    final Color effectiveBorder = borderColor ?? cs.hentai.borderSubtle;
    final Color effectiveTextColor = textColor ?? cs.hentai.textSecondary;

    final Widget label = _OutlinedMetaChipLabel(
      text: text,
      color: effectiveTextColor,
    );
    final Widget content = onRemove == null
        ? label
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(child: label),
              SizedBox(width: tokens.spacing.xs),
              _OutlinedMetaChipRemoveButton(
                color: effectiveTextColor,
                onRemove: onRemove!,
              ),
            ],
          );

    if (onTap == null) {
      return Semantics(
        label: text,
        child: _OutlinedMetaChipChrome(
          backgroundColor: cs.surface,
          borderColor: effectiveBorder,
          borderRadius: borderRadius,
          child: content,
        ),
      );
    }

    return _InteractiveOutlinedMetaChip(
      text: text,
      borderColor: effectiveBorder,
      borderRadius: borderRadius,
      onTap: onTap!,
      child: content,
    );
  }
}

class _OutlinedMetaChipRemoveButton extends StatelessWidget {
  const _OutlinedMetaChipRemoveButton({
    required this.color,
    required this.onRemove,
  });

  final Color color;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 16,
      height: 16,
      child: IconButton(
        tooltip: '',
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
    required this.onTap,
    required this.child,
  });

  final String text;
  final Color borderColor;
  final BorderRadius borderRadius;
  final VoidCallback onTap;
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
    final Color backgroundColor = isPressed.value
        ? pressFill
        : isHovered.value
        ? hoverFill
        : cs.surface;

    return Semantics(
      button: true,
      label: text,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => isHovered.value = true,
        onExit: (_) {
          isHovered.value = false;
          isPressed.value = false;
        },
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (_) => isPressed.value = true,
          onTapUp: (_) => isPressed.value = false,
          onTapCancel: () => isPressed.value = false,
          onTap: onTap,
          child: _OutlinedMetaChipChrome(
            backgroundColor: backgroundColor,
            borderColor: borderColor,
            borderRadius: borderRadius,
            animate: true,
            child: child,
          ),
        ),
      ),
    );
  }
}

class _OutlinedMetaChipChrome extends StatelessWidget {
  const _OutlinedMetaChipChrome({
    required this.backgroundColor,
    required this.borderColor,
    required this.borderRadius,
    required this.child,
    this.animate = false,
  });

  final Color backgroundColor;
  final Color borderColor;
  final BorderRadius borderRadius;
  final Widget child;
  final bool animate;

  @override
  Widget build(BuildContext context) {
    const EdgeInsets padding = EdgeInsets.symmetric(
      horizontal: 12,
      vertical: 6,
    );
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
  const _OutlinedMetaChipLabel({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final AppThemeTokens tokens = context.tokens;
    return Text(
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
  }
}
