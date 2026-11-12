import 'package:flutter/material.dart';
import 'package:hentai_library/design-system/design_system.dart';
import 'package:hentai_library/features/home/presentation/views/home/home_page_metrics.dart';
import 'package:hentai_library/core/l10n/app_localizations.dart';
import 'package:hentai_library/core/l10n/app_localizations_x.dart';
import 'package:hentai_library/shared/ui/patterns/home/home_aggregate_counts.dart';
import 'package:hentai_library/features/home/presentation/views/home/patterns/home_aggregate_stats_section.dart';
import 'package:hentai_library/features/reading_stats/public.dart';
import 'package:hentai_library/features/home/presentation/views/home/patterns/home_page_header.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

/// 生产首页（MD3E）：问候 + 页头 + 聚合统计（含快捷 bento）+ 库列表。
class HomeLayout extends StatelessWidget {
  const HomeLayout({
    super.key,
    required this.aggregateCounts,
    required this.activityStats,
    required this.libraryManagementSection,
    this.onOpenNavigation,
    this.onOpenHistory,
    this.onOpenTrash,
    this.onOpenAuthors,
    this.onOpenParodies,
    this.onOpenCharacters,
    this.onOpenTags,
  });

  final HomeAggregateCounts aggregateCounts;
  final ReadingActivityStats activityStats;
  final Widget libraryManagementSection;
  final VoidCallback? onOpenNavigation;
  final VoidCallback? onOpenHistory;
  final VoidCallback? onOpenTrash;
  final VoidCallback? onOpenAuthors;
  final VoidCallback? onOpenParodies;
  final VoidCallback? onOpenCharacters;
  final VoidCallback? onOpenTags;

  @override
  Widget build(BuildContext context) {
    final PageLayoutSpec layout = PageLayoutSpec.of(context);
    final WindowSizeClass sizeClass = layout.sizeClass;
    final AppLocalizations l10n = context.l10n;
    final M3EThemeData theme = M3ETheme.of(context);
    final M3EColorScheme scheme = theme.colorScheme;
    final String greeting = l10n.homeGreetingReader(
      l10n.homeGreetingPhraseForHour(DateTime.now().hour),
    );

    return ColoredBox(
      color: labBrowseCanvasColor(scheme),
      child: CustomScrollView(
        slivers: <Widget>[
          PageHeaderSliver(
            layout: layout,
            pinned: false,
            child: HomePageHeader(onOpenNavigation: onOpenNavigation),
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
                    height: HomePageMetrics.greetingToSectionSpacing(sizeClass),
                  ),
                  HomeAggregateStatsSection(
                    counts: aggregateCounts,
                    activityStats: activityStats,
                    onOpenHistory: onOpenHistory,
                    onOpenTrash: onOpenTrash,
                    onOpenAuthors: onOpenAuthors,
                    onOpenParodies: onOpenParodies,
                    onOpenCharacters: onOpenCharacters,
                    onOpenTags: onOpenTags,
                  ),
                  SizedBox(
                    height: HomePageMetrics.sectionVerticalSpacing(sizeClass),
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
