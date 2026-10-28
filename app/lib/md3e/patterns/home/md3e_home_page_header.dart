import 'package:flutter/material.dart';
import 'package:hentai_library/md3e/l10n/md3e_l10n.dart';
import 'package:hentai_library/md3e/layout/md3e_breakpoints.dart';
import 'package:hentai_library/md3e/patterns/library/md3e_library_page_header_metrics.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_symbols_icons/symbols.dart';

/// 首页粘滞顶栏：compact 可打开导航；标题为 [AppLocalizations.navHome]。
class Md3eHomePageHeader extends StatelessWidget {
  const Md3eHomePageHeader({
    super.key,
    this.onOpenNavigation,
  });

  final VoidCallback? onOpenNavigation;

  @override
  Widget build(BuildContext context) {
    final double windowWidth = MediaQuery.sizeOf(context).width;
    final Md3eWindowSizeClass sizeClass =
        Md3eWindowSizeClass.fromWidth(windowWidth);
    final AppLocalizations l10n = context.l10n;
    final M3EThemeData theme = M3ETheme.of(context);
    final M3EColorScheme scheme = theme.colorScheme;
    final M3ETypeScale type = theme.typeScale;
    final bool showMenu = sizeClass.isCompact && onOpenNavigation != null;

    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: Md3eLibraryPageHeaderMetrics.verticalPadding,
      ),
      child: SizedBox(
        height: Md3eLibraryPageHeaderMetrics.toolbarHeight,
        child: Row(
          children: <Widget>[
            if (showMenu) ...<Widget>[
              M3EIconButton(
                icon: Icon(
                  Symbols.menu,
                  size: Md3eLibraryPageHeaderMetrics.actionIconSize,
                  color: scheme.onSurfaceVariant,
                ),
                variant: M3EIconButtonVariant.standard,
                size: M3EIconButtonSize.sm,
                tooltip: l10n.shellOpenNavMenu,
                semanticLabel: l10n.shellOpenNavMenu,
                onPressed: onOpenNavigation,
              ),
              const SizedBox(width: 4),
            ],
            Expanded(
              child: Text(
                l10n.navHome,
                style: type.headlineSmall.copyWith(
                  fontSize: Md3eLibraryPageHeaderMetrics.titleFontSize(
                    sizeClass,
                  ),
                  fontWeight: Md3eLibraryPageHeaderMetrics.titleFontWeight(
                    sizeClass,
                  ),
                  color: scheme.onSurface,
                  letterSpacing: -0.4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
