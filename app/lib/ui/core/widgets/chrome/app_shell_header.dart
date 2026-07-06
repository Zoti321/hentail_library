import 'package:flutter/material.dart';
import 'package:hentai_library/ui/core/theme/theme.dart';
import 'package:hentai_library/ui/core/widgets/actions/ghost_button.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// 非桌面平台顶栏：SafeArea + 可选汉堡菜单 + 页面标题。
class AppShellHeader extends StatelessWidget {
  const AppShellHeader({
    super.key,
    required this.title,
    this.onMenuPressed,
  });

  final String title;
  final VoidCallback? onMenuPressed;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final AppThemeTokens tokens = context.tokens;

    return ColoredBox(
      color: cs.surface,
      child: SafeArea(
        bottom: false,
        child: Container(
          height: 48,
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: cs.hentai.borderSubtle, width: 1),
            ),
          ),
          padding: EdgeInsets.symmetric(horizontal: tokens.spacing.sm),
          child: Row(
            children: <Widget>[
              if (onMenuPressed != null) ...<Widget>[
                GhostButton.icon(
                  icon: LucideIcons.menu,
                  semanticLabel: '打开导航菜单',
                  tooltip: '',
                  size: 36,
                  borderRadius: tokens.radius.sm,
                  onPressed: onMenuPressed,
                ),
                SizedBox(width: tokens.spacing.xs),
              ],
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: cs.hentai.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
