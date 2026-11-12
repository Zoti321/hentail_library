import 'package:flutter/material.dart';
import 'package:hentai_library/core/l10n/app_localizations.dart';
import 'package:hentai_library/core/l10n/app_localizations_x.dart';
import 'package:hentai_library/design-system/design_system.dart';

/// 首页顶栏：标题为 [AppLocalizations.navHome]（主导航由壳层底部栏 / Rail 承担）。
class HomePageHeader extends StatelessWidget {
  const HomePageHeader({super.key, this.onOpenNavigation});

  final VoidCallback? onOpenNavigation;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;

    // 上下内边距与水平留白由外层 PageHeaderSliver / Chrome 提供，这里只负责工具行。
    return LibraryToolbarRow(
      title: PageTitle(l10n.navHome),
      onOpenNavigation: onOpenNavigation,
      menuTooltip: l10n.shellOpenNavMenu,
      menuSemanticLabel: l10n.shellOpenNavMenu,
    );
  }
}
