import 'package:flutter/material.dart';
import 'package:hentai_library/design-system/design_system.dart';
import 'package:hentai_library/features/home/presentation/l10n/home_l10n.dart';
import 'package:hentai_library/features/home/presentation/views/home/home_page_metrics.dart';
import 'package:hentai_library/features/home/presentation/views/home/patterns/home_aggregate_stats_section.dart';
import 'package:hentai_library/features/home/presentation/views/home/patterns/home_bento_stat_card.dart';
import 'package:hentai_library/features/home/presentation/views/home/patterns/home_page_header.dart';
import 'package:hentai_library/features/home/presentation/views/home/patterns/home_shortcut_card_colors.dart';
import 'package:hentai_library/features/reading_stats/public.dart';
import 'package:hentai_library/l10n/app_localizations.dart';
import 'package:hentai_library/shared/ui/l10n/app_localizations_x.dart';
import 'package:hentai_library/shared/ui/patterns/home/home_aggregate_counts.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_symbols_icons/symbols.dart';

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
    this.onOpenMedia,
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
  final VoidCallback? onOpenMedia;
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
                  if (onOpenMedia != null) ...<Widget>[
                    SizedBox(
                      height: HomePageMetrics.sectionVerticalSpacing(
                        sizeClass,
                      ),
                    ),
                    HomeBentoStatCard(
                      label: l10n.mediaTitle,
                      caption: l10n.mediaSubtitle,
                      icon: Symbols.perm_media,
                      backgroundColor: HomeShortcutCardColors.mediaBackground(
                        scheme,
                      ),
                      onBackgroundColor:
                          HomeShortcutCardColors.mediaForeground(scheme),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(28),
                        topRight: Radius.circular(12),
                        bottomLeft: Radius.circular(12),
                        bottomRight: Radius.circular(28),
                      ),
                      layout: HomeBentoStatLayout.shortcut,
                      minHeight: 104,
                      onPressed: onOpenMedia,
                    ),
                  ],
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
