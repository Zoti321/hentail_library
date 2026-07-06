import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hentai_library/ui/core/theme/theme.dart';
import 'package:hentai_library/ui/core/widgets/actions/ghost_button.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// 通用路由 404 页，用于已移除或无效的路径。
class RouteNotFoundPage extends StatelessWidget {
  const RouteNotFoundPage({super.key});

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final AppThemeTokens tokens = context.tokens;
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: tokens.spacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: tokens.spacing.lg,
          children: <Widget>[
            Icon(
              LucideIcons.circleAlert,
              size: 48,
              color: cs.hentai.textTertiary,
            ),
            Text(
              '页面不存在',
              style: TextStyle(
                fontSize: tokens.text.titleSm,
                fontWeight: FontWeight.w600,
                color: cs.hentai.textPrimary,
              ),
            ),
            Text(
              '你访问的链接可能已失效，或页面已被移除。',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: tokens.text.bodySm,
                color: cs.hentai.textSecondary,
              ),
            ),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: tokens.spacing.sm,
              runSpacing: tokens.spacing.sm,
              children: <Widget>[
                GhostButton.iconText(
                  icon: LucideIcons.house,
                  text: '返回首页',
                  onPressed: () => context.go('/home'),
                ),
                GhostButton.iconText(
                  icon: LucideIcons.library,
                  text: '去漫画库',
                  onPressed: () => context.go('/local'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
