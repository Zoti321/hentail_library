import 'package:flutter/material.dart';
import 'package:hentai_library/core/l10n/app_localizations.dart';
import 'package:hentai_library/core/l10n/app_localizations_x.dart';
import 'package:hentai_library/design-system/design_system.dart';
import 'package:hentai_library/features/home/presentation/views/home/home_page_metrics.dart';
import 'package:hentai_library/features/reading_stats/public.dart';
import 'package:hentai_library/shared/ui/patterns/home/home_aggregate_counts.dart';
import 'package:hentai_library/features/home/presentation/patterns/home/reading_duration_format.dart';
import 'package:hentai_library/features/home/presentation/views/home/patterns/home_activity_stats_capsule.dart';
import 'package:hentai_library/features/home/presentation/views/home/patterns/home_bento_stat_card.dart';
import 'package:hentai_library/features/home/presentation/views/home/patterns/home_page_copy.dart';
import 'package:hentai_library/features/home/presentation/views/home/patterns/home_shortcut_card_colors.dart';
import 'package:intl/intl.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_symbols_icons/symbols.dart';

/// 首页「全库统计」：阅读活动胶囊 + Kazumi 风 bento 色块 + 历史 / 垃圾桶入口。
///
/// 读完 / 时长合并为胶囊双指标；作者 / 原作 / 角色 / 标签用 shortcut 跳转管理 tab。
class HomeAggregateStatsSection extends StatelessWidget {
  const HomeAggregateStatsSection({
    super.key,
    required this.counts,
    required this.activityStats,
    this.onOpenHistory,
    this.onOpenTrash,
    this.onOpenAuthors,
    this.onOpenParodies,
    this.onOpenCharacters,
    this.onOpenTags,
  });

  final HomeAggregateCounts counts;
  final ReadingActivityStats activityStats;
  final VoidCallback? onOpenHistory;
  final VoidCallback? onOpenTrash;
  final VoidCallback? onOpenAuthors;
  final VoidCallback? onOpenParodies;
  final VoidCallback? onOpenCharacters;
  final VoidCallback? onOpenTags;

  bool get _showsShortcutCards => onOpenHistory != null && onOpenTrash != null;

  @override
  Widget build(BuildContext context) {
    final WindowSizeClass sizeClass = PageLayoutSpec.of(context).sizeClass;
    final M3EThemeData theme = M3ETheme.of(context);
    final M3EColorScheme scheme = theme.colorScheme;
    final M3ETypeScale type = theme.typeScale;
    final AppLocalizations l10n = context.l10n;
    final String locale = Localizations.localeOf(context).toString();
    final NumberFormat numberFormat = NumberFormat.decimalPattern(locale);
    final double gap = HomePageMetrics.statCardGap(sizeClass);
    final double tagsTopGap = HomePageMetrics.statTagsRowTopGap(sizeClass);
    final _HomeStatPalette palette = _HomeStatPalette(scheme);

    String formatCount(int value) => numberFormat.format(value);

    Widget activityCapsule() {
      return HomeActivityStatsCapsule(
        title: HomePageCopy.activityStatsTitle,
        leftValue: formatCount(activityStats.finishedCount),
        leftLabel: l10n.homeStatFinishedComics,
        rightValue: formatReadingDurationForDisplay(
          activityStats.totalDuration,
          l10n,
        ),
        rightLabel: l10n.homeStatReadingDuration,
      );
    }

    Widget comicCard({required HomeBentoStatEmphasis emphasis}) {
      return HomeBentoStatCard(
        label: HomePageCopy.comicsStatLabel,
        valueText: formatCount(counts.comicCount),
        caption: l10n.homeComicTotal(counts.comicCount),
        icon: Symbols.auto_stories,
        backgroundColor: palette.comicsBackground,
        onBackgroundColor: palette.comicsForeground,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(12),
          bottomLeft: Radius.circular(12),
          bottomRight: Radius.circular(28),
        ),
        minHeight: emphasis == HomeBentoStatEmphasis.hero ? 132 : 104,
        emphasis: emphasis,
      );
    }

    Widget seriesCard() {
      return HomeBentoStatCard(
        label: l10n.homeStatSeries,
        valueText: formatCount(counts.seriesCount),
        caption: l10n.homeSeriesCount(counts.seriesCount),
        icon: Symbols.collections_bookmark,
        backgroundColor: palette.seriesBackground,
        onBackgroundColor: palette.seriesForeground,
        borderRadius: BorderRadius.circular(20),
        minHeight: 104,
      );
    }

    Widget authorCard() {
      return HomeBentoStatCard(
        label: l10n.homeStatAuthors,
        caption: counts.authorCount == 0
            ? l10n.homeNoAuthors
            : l10n.homeAuthorCount(counts.authorCount),
        icon: Symbols.draw,
        backgroundColor: palette.authorsBackground,
        onBackgroundColor: palette.authorsForeground,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(8),
          topRight: Radius.circular(24),
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(8),
        ),
        layout: HomeBentoStatLayout.shortcut,
        onPressed: onOpenAuthors,
      );
    }

    Widget parodyCard() {
      return HomeBentoStatCard(
        label: l10n.metadataTabParodies,
        caption: l10n.metadataParodyCount(counts.parodyCount),
        icon: Symbols.theaters,
        backgroundColor: palette.parodiesBackground,
        onBackgroundColor: palette.parodiesForeground,
        borderRadius: const BorderRadius.all(Radius.circular(16)),
        minHeight: 108,
        layout: HomeBentoStatLayout.shortcut,
        onPressed: onOpenParodies,
      );
    }

    Widget characterCard() {
      return HomeBentoStatCard(
        label: l10n.metadataTabCharacters,
        caption: l10n.metadataCharacterCount(counts.characterCount),
        icon: Symbols.face_3,
        backgroundColor: palette.charactersBackground,
        onBackgroundColor: palette.charactersForeground,
        borderRadius: BorderRadius.circular(16),
        emphasis: HomeBentoStatEmphasis.compact,
        layout: HomeBentoStatLayout.shortcut,
        onPressed: onOpenCharacters,
      );
    }

    Widget tagCard({required bool wide}) {
      return HomeBentoStatCard(
        label: l10n.homeStatTags,
        caption: l10n.homeTagCount(counts.tagCount),
        icon: Symbols.label,
        backgroundColor: palette.tagsBackground,
        onBackgroundColor: palette.tagsForeground,
        borderRadius: wide
            ? const BorderRadius.horizontal(left: Radius.circular(40))
            : BorderRadius.circular(40),
        minHeight: wide ? 88 : 96,
        emphasis: HomeBentoStatEmphasis.compact,
        layout: HomeBentoStatLayout.shortcut,
        contentPadding: HomePageMetrics.statCardContentPadding(
          sizeClass,
          tagPill: true,
        ),
        onPressed: onOpenTags,
      );
    }

    Widget historyCard() {
      return HomeBentoStatCard(
        label: l10n.historyTitle,
        caption: l10n.homeHistoryCardCaption,
        icon: Symbols.history,
        backgroundColor: palette.historyBackground,
        onBackgroundColor: palette.historyForeground,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(8),
          bottomLeft: Radius.circular(8),
          bottomRight: Radius.circular(20),
        ),
        layout: HomeBentoStatLayout.shortcut,
        minHeight: 104,
        onPressed: onOpenHistory!,
      );
    }

    Widget trashCard() {
      return HomeBentoStatCard(
        label: l10n.navTrash,
        caption: l10n.homeTrashCardCaption,
        icon: Symbols.delete_outline,
        backgroundColor: palette.trashBackground,
        onBackgroundColor: palette.trashForeground,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(8),
          topRight: Radius.circular(20),
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(8),
        ),
        layout: HomeBentoStatLayout.shortcut,
        minHeight: 104,
        onPressed: onOpenTrash!,
      );
    }

    Widget shortcutRow() {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(child: historyCard()),
          SizedBox(width: gap),
          Expanded(child: trashCard()),
        ],
      );
    }

    final Widget grid = switch (sizeClass) {
      WindowSizeClass.compact => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          activityCapsule(),
          SizedBox(height: gap),
          comicCard(emphasis: HomeBentoStatEmphasis.hero),
          if (_showsShortcutCards) ...<Widget>[
            SizedBox(height: gap),
            shortcutRow(),
          ],
          SizedBox(height: gap),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(child: seriesCard()),
              SizedBox(width: gap),
              Expanded(child: authorCard()),
            ],
          ),
          SizedBox(height: gap),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(child: parodyCard()),
              SizedBox(width: gap),
              Expanded(child: characterCard()),
            ],
          ),
          SizedBox(height: tagsTopGap),
          tagCard(wide: false),
        ],
      ),
      _ => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          activityCapsule(),
          SizedBox(height: gap),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Expanded(
                  flex: 3,
                  child: comicCard(emphasis: HomeBentoStatEmphasis.hero),
                ),
                SizedBox(width: gap),
                Expanded(flex: 2, child: seriesCard()),
              ],
            ),
          ),
          if (_showsShortcutCards) ...<Widget>[
            SizedBox(height: gap),
            shortcutRow(),
          ],
          SizedBox(height: gap),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Expanded(child: authorCard()),
                SizedBox(width: gap),
                Expanded(child: parodyCard()),
                SizedBox(width: gap),
                Expanded(child: characterCard()),
              ],
            ),
          ),
          SizedBox(height: tagsTopGap),
          tagCard(wide: true),
        ],
      ),
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(
          HomePageCopy.aggregateStatsSectionTitle,
          style: type.titleLarge.copyWith(color: scheme.onSurface),
        ),
        SizedBox(height: theme.spacing.md),
        grid,
      ],
    );
  }
}

class _HomeStatPalette {
  _HomeStatPalette(M3EColorScheme scheme)
    : comicsBackground = scheme.primaryContainer,
      comicsForeground = scheme.onPrimaryContainer,
      seriesBackground = scheme.secondaryContainer,
      seriesForeground = scheme.onSecondaryContainer,
      // 浅紫 secondary，避开 tertiary 芥末黄；与系列/垃圾桶同系但不同行。
      authorsBackground = scheme.secondaryContainer,
      authorsForeground = scheme.onSecondaryContainer,
      parodiesBackground = scheme.surfaceContainerHighest,
      parodiesForeground = scheme.onSurface,
      charactersBackground = scheme.emphasis,
      charactersForeground = scheme.onEmphasis,
      tagsBackground = scheme.surfaceContainerHigh,
      tagsForeground = scheme.onSurface,
      historyBackground = HomeShortcutCardColors.historyBackground(scheme),
      historyForeground = HomeShortcutCardColors.historyForeground(scheme),
      trashBackground = HomeShortcutCardColors.trashBackground(scheme),
      trashForeground = HomeShortcutCardColors.trashForeground(scheme);

  final Color comicsBackground;
  final Color comicsForeground;
  final Color seriesBackground;
  final Color seriesForeground;
  final Color authorsBackground;
  final Color authorsForeground;
  final Color parodiesBackground;
  final Color parodiesForeground;
  final Color charactersBackground;
  final Color charactersForeground;
  final Color tagsBackground;
  final Color tagsForeground;
  final Color historyBackground;
  final Color historyForeground;
  final Color trashBackground;
  final Color trashForeground;
}
