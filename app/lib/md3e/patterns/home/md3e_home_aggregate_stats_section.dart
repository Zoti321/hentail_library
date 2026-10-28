import 'package:flutter/material.dart';
import 'package:hentai_library/md3e/l10n/md3e_l10n.dart';
import 'package:hentai_library/md3e/layout/md3e_breakpoints.dart';
import 'package:hentai_library/md3e/layout/md3e_home_page_metrics.dart';
import 'package:hentai_library/md3e/patterns/home/md3e_home_aggregate_counts.dart';
import 'package:hentai_library/md3e/patterns/home/md3e_home_bento_stat_card.dart';
import 'package:hentai_library/md3e/patterns/home/md3e_home_page_copy.dart';
import 'package:intl/intl.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_symbols_icons/symbols.dart';

/// 首页「全库统计」：Kazumi 风 bento 色块（漫画/系列/作者/原作/角色/标签）。
class Md3eHomeAggregateStatsSection extends StatelessWidget {
  const Md3eHomeAggregateStatsSection({
    super.key,
    required this.counts,
  });

  final Md3eHomeAggregateCounts counts;

  @override
  Widget build(BuildContext context) {
    final Md3eWindowSizeClass sizeClass = Md3eWindowSizeClass.fromWidth(
      MediaQuery.sizeOf(context).width,
    );
    final M3EThemeData theme = M3ETheme.of(context);
    final M3EColorScheme scheme = theme.colorScheme;
    final M3ETypeScale type = theme.typeScale;
    final AppLocalizations l10n = context.l10n;
    final String locale = Localizations.localeOf(context).toString();
    final NumberFormat numberFormat = NumberFormat.decimalPattern(locale);
    final double gap = Md3eHomePageMetrics.statCardGap(sizeClass);
    final double tagsTopGap = Md3eHomePageMetrics.statTagsRowTopGap(sizeClass);
    final _Md3eHomeStatPalette palette = _Md3eHomeStatPalette(scheme);

    String formatCount(int value) => numberFormat.format(value);

    Widget comicCard({required Md3eHomeBentoStatEmphasis emphasis}) {
      return Md3eHomeBentoStatCard(
        label: Md3eHomePageCopy.comicsStatLabel,
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
        minHeight: emphasis == Md3eHomeBentoStatEmphasis.hero ? 132 : 104,
        emphasis: emphasis,
      );
    }

    Widget seriesCard() {
      return Md3eHomeBentoStatCard(
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
      return Md3eHomeBentoStatCard(
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
      return Md3eHomeBentoStatCard(
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
      return Md3eHomeBentoStatCard(
        label: l10n.metadataTabCharacters,
        valueText: formatCount(counts.characterCount),
        caption: l10n.metadataCharacterCount(counts.characterCount),
        icon: Symbols.face_3,
        backgroundColor: palette.charactersBackground,
        onBackgroundColor: palette.charactersForeground,
        borderRadius: BorderRadius.circular(16),
        emphasis: Md3eHomeBentoStatEmphasis.compact,
      );
    }

    Widget tagCard({required bool wide}) {
      return Md3eHomeBentoStatCard(
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
        emphasis: Md3eHomeBentoStatEmphasis.compact,
        contentPadding: Md3eHomePageMetrics.statCardContentPadding(
          sizeClass,
          tagPill: true,
        ),
      );
    }

    final Widget grid = switch (sizeClass) {
      Md3eWindowSizeClass.compact => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          comicCard(emphasis: Md3eHomeBentoStatEmphasis.hero),
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
                  child: comicCard(emphasis: Md3eHomeBentoStatEmphasis.hero),
                ),
                SizedBox(width: gap),
                Expanded(flex: 2, child: seriesCard()),
              ],
            ),
          ),
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
          Md3eHomePageCopy.aggregateStatsSectionTitle,
          style: type.titleLarge.copyWith(color: scheme.onSurface),
        ),
        SizedBox(height: theme.spacing.md),
        grid,
      ],
    );
  }
}

class _Md3eHomeStatPalette {
  _Md3eHomeStatPalette(M3EColorScheme scheme)
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
        tagsForeground = scheme.onSurface;

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
}
