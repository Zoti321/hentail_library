import 'package:flutter/material.dart';
import 'package:hentai_library/shared/ui/layout/breakpoints.dart';
import 'package:hentai_library/shared/ui/layout/page_layout_spec.dart';
import 'package:hentai_library/features/home/presentation/views/home_md3e/md3e_home_page_metrics.dart';
import 'package:hentai_library/core/l10n/app_localizations.dart';
import 'package:hentai_library/core/l10n/app_localizations_x.dart';
import 'package:hentai_library/shared/ui/shell/desktop_shell_surfaces.dart';
import 'package:hentai_library/shared/ui/patterns/home/home_aggregate_counts.dart';
import 'package:hentai_library/features/home/presentation/views/home_md3e/patterns/md3e_home_aggregate_stats_section.dart';
import 'package:hentai_library/shared/ui/patterns/shared/md3e_page_header.dart';
import 'package:hentai_library/features/home/presentation/views/home_md3e/patterns/md3e_home_page_header.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

/// 生产首页（MD3E）：问候 + 页头 + 聚合统计 + 库列表（由 [libraryManagementSection] 注入）。
class Md3eHomePage extends StatelessWidget {
  const Md3eHomePage({
    super.key,
    required this.aggregateCounts,
    required this.libraryManagementSection,
    this.onOpenNavigation,
  });

  final Md3eHomeAggregateCounts aggregateCounts;
  final Widget libraryManagementSection;
  final VoidCallback? onOpenNavigation;

  @override
  Widget build(BuildContext context) {
    final Md3ePageLayoutSpec layout = Md3ePageLayoutSpec.of(context);
    final Md3eWindowSizeClass sizeClass = layout.sizeClass;
    final AppLocalizations l10n = context.l10n;
    final M3EThemeData theme = M3ETheme.of(context);
    final M3EColorScheme scheme = theme.colorScheme;
    final String greeting = l10n.homeGreetingReader(
      l10n.homeGreetingPhraseForHour(DateTime.now().hour),
    );

    return ColoredBox(
      color: md3eLabBrowseCanvasColor(scheme),
      child: CustomScrollView(
        slivers: <Widget>[
          SliverPersistentHeader(
            pinned: true,
            delegate: Md3ePageHeaderDelegate(
              layout: layout,
              child: Md3eHomePageHeader(onOpenNavigation: onOpenNavigation),
            ),
          ),
          SliverPadding(
            padding: EdgeInsets.fromLTRB(
              layout.horizontalInset,
              layout.headerToBodyGap,
              layout.horizontalInset,
              layout.bodyBottomInset,
            ),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Text(
                    greeting,
                    style: theme.typeScale.titleMedium.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  SizedBox(
                    height: Md3eHomePageMetrics.greetingToSectionSpacing(
                      sizeClass,
                    ),
                  ),
                  Md3eHomeAggregateStatsSection(counts: aggregateCounts),
                  SizedBox(
                    height: Md3eHomePageMetrics.sectionVerticalSpacing(
                      sizeClass,
                    ),
                  ),
                  libraryManagementSection,
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
