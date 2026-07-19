import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hentai_library/core/l10n/app_localizations_x.dart';
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
    final l10n = context.l10n;
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
              l10n.notFoundTitle,
              style: TextStyle(
                fontSize: tokens.text.titleSm,
                fontWeight: FontWeight.w600,
                color: cs.hentai.textPrimary,
              ),
            ),
            Text(
              l10n.notFoundHint,
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
                  text: l10n.notFoundGoHome,
                  onPressed: () => context.go('/home'),
                ),
                GhostButton.iconText(
                  icon: LucideIcons.library,
                  text: l10n.notFoundGoLibrary,
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
