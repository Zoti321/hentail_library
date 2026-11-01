import 'package:flutter/material.dart';
import 'package:hentai_library/core/l10n/app_localizations.dart';
import 'package:hentai_library/core/l10n/app_localizations_x.dart';
import 'package:hentai_library/shared/ui/layout/page_layout_spec.dart';
import 'package:hentai_library/shared/ui/patterns/library/library_page_header_metrics.dart';
import 'package:hentai_library/shared/ui/patterns/shared/md3e_page_title.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_symbols_icons/symbols.dart';

/// 首页顶栏：compact 可打开导航；标题为 [AppLocalizations.navHome]。
class Md3eHomePageHeader extends StatelessWidget {
  const Md3eHomePageHeader({super.key, this.onOpenNavigation});

  final VoidCallback? onOpenNavigation;

  @override
  Widget build(BuildContext context) {
    final Md3ePageLayoutSpec layout = Md3ePageLayoutSpec.of(context);
    final AppLocalizations l10n = context.l10n;
    final M3EColorScheme scheme = M3ETheme.of(context).colorScheme;
    final bool showMenu =
        layout.sizeClass.isCompact && onOpenNavigation != null;

    // 上下内边距与水平留白由外层 Md3ePageHeaderDelegate 提供，这里只负责工具行。
    return SizedBox(
      height: Md3ePageLayoutSpec.toolbarRowHeight,
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
          Expanded(child: Md3ePageTitle(l10n.navHome)),
        ],
      ),
    );
  }
}
