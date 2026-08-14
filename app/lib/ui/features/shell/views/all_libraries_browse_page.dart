import 'package:flutter/material.dart';
import 'package:hentai_library/core/l10n/app_localizations_x.dart';
import 'package:hentai_library/ui/core/theme/theme.dart';
import 'package:hentai_library/ui/core/widgets/actions/ghost_button.dart';
import 'package:hentai_library/ui/features/shell/views/responsive_app_shell.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Placeholder for All libraries browse (`/libraries/all`).
class AllLibrariesBrowsePage extends StatelessWidget {
  const AllLibrariesBrowsePage({super.key});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme cs = theme.colorScheme;
    final AppThemeTokens tokens = context.tokens;
    final l10n = context.l10n;
    final VoidCallback? openNav = appShellPageNavigationOpener(context);

    return ColoredBox(
      color: cs.hentai.winBackground,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Padding(
            padding: EdgeInsets.fromLTRB(
              tokens.spacing.md,
              tokens.spacing.md,
              tokens.spacing.md,
              tokens.spacing.sm,
            ),
            child: Row(
              children: <Widget>[
                if (openNav != null)
                  GhostButton.icon(
                    icon: LucideIcons.menu,
                    tooltip: l10n.shellOpenNavMenu,
                    semanticLabel: l10n.shellOpenNavMenu,
                    iconSize: 18,
                    size: 36,
                    borderRadius: tokens.radius.md,
                    foregroundColor: cs.hentai.textSecondary,
                    hoverColor: cs.hentai.sidebarItemHoverBackground,
                    overlayColor: cs.hentai.sidebarItemHoverBackground
                        .withAlpha(110),
                    onPressed: openNav,
                  ),
                Expanded(
                  child: Text(
                    l10n.libraryTitle,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: cs.hentai.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Center(
              child: Padding(
                padding: EdgeInsets.all(tokens.spacing.xl),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Icon(
                        LucideIcons.library,
                        size: 40,
                        color: cs.hentai.textTertiary,
                      ),
                      SizedBox(height: tokens.spacing.md),
                      Text(
                        l10n.allLibrariesBrowsePlaceholderTitle,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: cs.hentai.textPrimary,
                        ),
                      ),
                      SizedBox(height: tokens.spacing.sm),
                      Text(
                        l10n.allLibrariesBrowsePlaceholderBody,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: cs.hentai.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
