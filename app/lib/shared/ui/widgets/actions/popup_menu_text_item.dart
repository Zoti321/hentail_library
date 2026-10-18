import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hentai_library/shared/ui/theme/theme.dart';

/// 菜单面板内的文本菜单项：hover 高亮，支持禁用与危险样式（由侧栏与元数据菜单共用）。
class PopupMenuTextItem extends HookWidget {
  const PopupMenuTextItem({
    super.key,
    required this.label,
    this.onTap,
    this.enabled = true,
    this.isDestructive = false,
  });

  final String label;
  final VoidCallback? onTap;
  final bool enabled;
  final bool isDestructive;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme cs = theme.colorScheme;
    final AppThemeTokens tokens = context.tokens;
    final HentaiColorScheme h = cs.hentai;
    final ValueNotifier<bool> hovered = useState(false);

    // Idle must be opaque (panel surface). Lerping from Colors.transparent
    // goes through muddy greys and looks like a broken color animation.
    final Color idleBackground = cs.surface;
    // Light danger wash (not solid red) so hover stays readable.
    final Color dangerHover = Color.lerp(
      idleBackground,
      h.contextMenuDanger,
      0.2,
    )!;

    final Color background;
    final Color foreground;
    if (!enabled) {
      background = idleBackground;
      foreground = h.textTertiary;
    } else if (hovered.value) {
      background = isDestructive ? dangerHover : h.contextMenuHover;
      foreground = isDestructive ? h.contextMenuDanger : h.textPrimary;
    } else {
      background = idleBackground;
      foreground = h.textPrimary;
    }

    // copyWith keeps ThemeData.fontFamily (MI_Sans_Regular); a bare TextStyle
    // under AnimatedDefaultTextStyle would fall back to the platform font.
    final TextStyle labelStyle =
        (theme.textTheme.bodyMedium ?? const TextStyle()).copyWith(
          fontSize: tokens.text.bodySm,
          color: foreground,
        );

    return MouseRegion(
      onEnter: enabled ? (_) => hovered.value = true : null,
      onExit: enabled ? (_) => hovered.value = false : null,
      cursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
      child: GestureDetector(
        onTap: enabled ? onTap : null,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOut,
          color: background,
          padding: EdgeInsets.symmetric(
            horizontal: tokens.spacing.md,
            vertical: tokens.spacing.sm,
          ),
          child: AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 120),
            curve: Curves.easeOut,
            style: labelStyle,
            child: Text(label, textAlign: TextAlign.start),
          ),
        ),
      ),
    );
  }
}
