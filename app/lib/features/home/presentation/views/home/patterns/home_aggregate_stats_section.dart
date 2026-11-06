import 'package:flutter/material.dart';
import 'package:hentai_library/core/l10n/app_localizations.dart';
import 'package:hentai_library/core/l10n/app_localizations_x.dart';
import 'package:hentai_library/shared/ui/layout/breakpoints.dart';
import 'package:hentai_library/shared/ui/layout/page_layout_spec.dart';
import 'package:hentai_library/features/home/presentation/views/home/home_page_metrics.dart';
import 'package:hentai_library/shared/ui/patterns/home/home_aggregate_counts.dart';
import 'package:hentai_library/features/home/presentation/views/home/patterns/home_bento_stat_card.dart';
import 'package:hentai_library/features/home/presentation/views/home/patterns/home_page_copy.dart';
import 'package:hentai_library/features/home/presentation/views/home/patterns/home_nav_shortcut_card.dart';
import 'package:hentai_library/features/home/presentation/views/home/patterns/home_shortcut_card_colors.dart';
import 'package:intl/intl.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_symbols_icons/symbols.dart';

/// 首页「全库统计」：Kazumi 风 bento 色块 + 历史 / 垃圾桶入口卡片。
class HomeAggregateStatsSection extends StatelessWidget {
  const HomeAggregateStatsSection({
    super.key,
    required this.counts,
    this.onOpenHistory,
    this.onOpenTrash,
  });

  final HomeAggregateCounts counts;
  final VoidCallback? onOpenHistory;
  final VoidCallback? onOpenTrash;

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
        valueText: formatCount(counts.authorCount),
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
      );
    }

    Widget parodyCard() {
      return HomeBentoStatCard(
        label: l10n.metadataTabParodies,
        valueText: formatCount(counts.parodyCount),
        caption: l10n.metadataParodyCount(counts.parodyCount),
        icon: Symbols.theaters,
        backgroundColor: palette.parodiesBackground,
        onBackgroundColor: palette.parodiesForeground,
        borderRadius: const BorderRadius.all(Radius.circular(16)),
        minHeight: 108,
      );
    }

    Widget characterCard() {
      return HomeBentoStatCard(
        label: l10n.metadataTabCharacters,
        valueText: formatCount(counts.characterCount),
        caption: l10n.metadataCharacterCount(counts.characterCount),
        icon: Symbols.face_3,
        backgroundColor: palette.charactersBackground,
        onBackgroundColor: palette.charactersForeground,
        borderRadius: BorderRadius.circular(16),
        emphasis: HomeBentoStatEmphasis.compact,
      );
    }

    Widget tagCard({required bool wide}) {
      return HomeBentoStatCard(
        label: l10n.homeStatTags,
        valueText: formatCount(counts.tagCount),
        caption: l10n.homeTagCount(counts.tagCount),
        icon: Symbols.label,
        backgroundColor: palette.tagsBackground,
        onBackgroundColor: palette.tagsForeground,
        borderRadius: wide
            ? const BorderRadius.horizontal(left: Radius.circular(40))
            : BorderRadius.circular(40),
        minHeight: wide ? 88 : 96,
        emphasis: HomeBentoStatEmphasis.compact,
        contentPadding: HomePageMetrics.statCardContentPadding(
          sizeClass,
          tagPill: true,
        ),
      );
    }

    Widget historyCard() {
      return HomeNavShortcutCard(
        title: l10n.historyTitle,
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
        onPressed: onOpenHistory!,
      );
    }

    Widget trashCard() {
      return HomeNavShortcutCard(
        title: l10n.navTrash,
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
      authorsBackground = scheme.tertiaryContainer,
      authorsForeground = scheme.onTertiaryContainer,
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
