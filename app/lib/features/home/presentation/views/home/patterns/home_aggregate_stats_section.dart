import 'package:flutter/material.dart';
import 'package:hentai_library/l10n/app_localizations.dart';
import 'package:hentai_library/shared/ui/l10n/app_localizations_x.dart';
import 'package:hentai_library/design-system/design_system.dart';
import 'package:hentai_library/features/home/presentation/patterns/home/reading_duration_format.dart';
import 'package:hentai_library/features/home/presentation/views/home/home_page_metrics.dart';
import 'package:hentai_library/features/home/presentation/views/home/patterns/home_activity_stats_capsule.dart';
import 'package:hentai_library/features/home/presentation/views/home/patterns/home_bento_stat_card.dart';
import 'package:hentai_library/features/home/presentation/views/home/patterns/home_page_copy.dart';
import 'package:hentai_library/features/home/presentation/views/home/patterns/home_shortcut_card_colors.dart';
import 'package:hentai_library/features/reading_stats/public.dart';
import 'package:hentai_library/shared/ui/patterns/home/home_aggregate_counts.dart';
import 'package:intl/intl.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_symbols_icons/symbols.dart';

/// Personal center: reading activity, collection overview, metadata and utilities.
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
    final AppLocalizations l10n = context.l10n;
    final _StatsScope scope = _StatsScope(
      counts: counts,
      activityStats: activityStats,
      l10n: l10n,
      palette: _HomeStatPalette(scheme),
      numberFormat: NumberFormat.decimalPattern(
        Localizations.localeOf(context).toString(),
      ),
      sizeClass: sizeClass,
      gap: HomePageMetrics.statCardGap(sizeClass),
      onOpenHistory: _showsShortcutCards ? onOpenHistory : null,
      onOpenTrash: _showsShortcutCards ? onOpenTrash : null,
      onOpenAuthors: onOpenAuthors,
      onOpenParodies: onOpenParodies,
      onOpenCharacters: onOpenCharacters,
      onOpenTags: onOpenTags,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(
          HomePageCopy.aggregateStatsSectionTitle,
          style: theme.typeScale.titleLarge.copyWith(color: scheme.onSurface),
        ),
        SizedBox(height: theme.spacing.md),
        _StatsGrid(scope: scope),
      ],
    );
  }
}

class _StatsScope {
  const _StatsScope({
    required this.counts,
    required this.activityStats,
    required this.l10n,
    required this.palette,
    required this.numberFormat,
    required this.sizeClass,
    required this.gap,
    required this.onOpenHistory,
    required this.onOpenTrash,
    required this.onOpenAuthors,
    required this.onOpenParodies,
    required this.onOpenCharacters,
    required this.onOpenTags,
  });

  final HomeAggregateCounts counts;
  final ReadingActivityStats activityStats;
  final AppLocalizations l10n;
  final _HomeStatPalette palette;
  final NumberFormat numberFormat;
  final WindowSizeClass sizeClass;
  final double gap;
  final VoidCallback? onOpenHistory;
  final VoidCallback? onOpenTrash;
  final VoidCallback? onOpenAuthors;
  final VoidCallback? onOpenParodies;
  final VoidCallback? onOpenCharacters;
  final VoidCallback? onOpenTags;

  String formatCount(int value) => numberFormat.format(value);
}

class _StatsGrid extends StatelessWidget {
  const _StatsGrid({required this.scope});

  final _StatsScope scope;

  @override
  Widget build(BuildContext context) {
    return _PersonalCenterGrid(scope: scope);
  }
}

class _PersonalCenterGrid extends StatelessWidget {
  const _PersonalCenterGrid({required this.scope});

  final _StatsScope scope;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool compact = constraints.maxWidth < 760;
        final bool narrow = constraints.maxWidth < 360;
        final List<Widget> metadata = <Widget>[
          _AuthorStatCard(scope: scope),
          _ParodyStatCard(scope: scope),
          _CharacterStatCard(scope: scope),
          _TagStatCard(scope: scope),
        ];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            _ActivityCapsule(scope: scope),
            SizedBox(height: scope.gap),
            if (narrow) ...<Widget>[
              _ComicStatCard(
                scope: scope,
                emphasis: HomeBentoStatEmphasis.hero,
              ),
              SizedBox(height: scope.gap),
              _SeriesStatCard(scope: scope),
            ] else
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Expanded(
                      flex: compact ? 1 : 3,
                      child: _ComicStatCard(
                        scope: scope,
                        emphasis: HomeBentoStatEmphasis.hero,
                      ),
                    ),
                    SizedBox(width: scope.gap),
                    Expanded(
                      flex: compact ? 1 : 2,
                      child: _SeriesStatCard(scope: scope),
                    ),
                  ],
                ),
              ),
            SizedBox(height: scope.gap * 1.5),
            if (narrow) ...<Widget>[
              for (int i = 0; i < metadata.length; i++) ...<Widget>[
                if (i > 0) SizedBox(height: scope.gap),
                metadata[i],
              ],
            ] else if (compact) ...<Widget>[
              _MetadataCardRow(cards: metadata.sublist(0, 2), gap: scope.gap),
              SizedBox(height: scope.gap),
              _MetadataCardRow(cards: metadata.sublist(2), gap: scope.gap),
            ] else
              _MetadataCardRow(cards: metadata, gap: scope.gap),
            if (scope.onOpenHistory != null &&
                scope.onOpenTrash != null) ...<Widget>[
              SizedBox(height: scope.gap * 1.5),
              if (narrow) ...<Widget>[
                _HistoryStatCard(scope: scope),
                SizedBox(height: scope.gap),
                _TrashStatCard(scope: scope),
              ] else
                _ShortcutRow(scope: scope),
            ],
          ],
        );
      },
    );
  }
}

class _MetadataCardRow extends StatelessWidget {
  const _MetadataCardRow({required this.cards, required this.gap});
  final List<Widget> cards;
  final double gap;
  @override
  Widget build(BuildContext context) => IntrinsicHeight(
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < cards.length; i++) ...[
          if (i > 0) SizedBox(width: gap),
          Expanded(child: cards[i]),
        ],
      ],
    ),
  );
}

class _ActivityCapsule extends StatelessWidget {
  const _ActivityCapsule({required this.scope});

  final _StatsScope scope;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = scope.l10n;
    final ReadingActivityStats stats = scope.activityStats;
    return HomeActivityStatsCapsule(
      title: HomePageCopy.activityStatsTitle,
      leftValue: scope.formatCount(stats.finishedCount),
      leftLabel: l10n.homeStatFinishedComics,
      rightValue: formatReadingDurationForDisplay(stats.totalDuration, l10n),
      rightLabel: l10n.homeStatReadingDuration,
    );
  }
}

class _ComicStatCard extends StatelessWidget {
  const _ComicStatCard({required this.scope, required this.emphasis});

  final _StatsScope scope;
  final HomeBentoStatEmphasis emphasis;

  @override
  Widget build(BuildContext context) {
    final _HomeStatPalette palette = scope.palette;
    return HomeBentoStatCard(
      label: HomePageCopy.comicsStatLabel,
      valueText: scope.formatCount(scope.counts.comicCount),
      caption: scope.l10n.homeComicTotal(scope.counts.comicCount),
      icon: Symbols.auto_stories,
      backgroundColor: palette.comicsBackground,
      onBackgroundColor: palette.comicsForeground,
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(40),
        topRight: Radius.circular(12),
        bottomLeft: Radius.circular(12),
        bottomRight: Radius.circular(40),
      ),
      minHeight: emphasis == HomeBentoStatEmphasis.hero ? 132 : 104,
      emphasis: emphasis,
    );
  }
}

class _SeriesStatCard extends StatelessWidget {
  const _SeriesStatCard({required this.scope});

  final _StatsScope scope;

  @override
  Widget build(BuildContext context) {
    final _HomeStatPalette palette = scope.palette;
    return HomeBentoStatCard(
      label: scope.l10n.homeStatSeries,
      valueText: scope.formatCount(scope.counts.seriesCount),
      caption: scope.l10n.homeSeriesCount(scope.counts.seriesCount),
      icon: Symbols.collections_bookmark,
      backgroundColor: palette.seriesBackground,
      onBackgroundColor: palette.seriesForeground,
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(12),
        topRight: Radius.circular(40),
        bottomLeft: Radius.circular(40),
        bottomRight: Radius.circular(12),
      ),
      minHeight: 132,
    );
  }
}

class _AuthorStatCard extends StatelessWidget {
  const _AuthorStatCard({required this.scope});

  final _StatsScope scope;

  @override
  Widget build(BuildContext context) {
    final _HomeStatPalette palette = scope.palette;
    final int count = scope.counts.authorCount;
    return HomeBentoStatCard(
      label: scope.l10n.homeStatAuthors,
      caption: count == 0
          ? scope.l10n.homeNoAuthors
          : scope.l10n.homeAuthorCount(count),
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
      onPressed: scope.onOpenAuthors,
    );
  }
}

class _ParodyStatCard extends StatelessWidget {
  const _ParodyStatCard({required this.scope});

  final _StatsScope scope;

  @override
  Widget build(BuildContext context) {
    final _HomeStatPalette palette = scope.palette;
    return HomeBentoStatCard(
      label: scope.l10n.metadataTabParodies,
      caption: scope.l10n.metadataParodyCount(scope.counts.parodyCount),
      icon: Symbols.theaters,
      backgroundColor: palette.parodiesBackground,
      onBackgroundColor: palette.parodiesForeground,
      borderRadius: const BorderRadius.all(Radius.circular(16)),
      minHeight: 108,
      layout: HomeBentoStatLayout.shortcut,
      onPressed: scope.onOpenParodies,
    );
  }
}

class _CharacterStatCard extends StatelessWidget {
  const _CharacterStatCard({required this.scope});

  final _StatsScope scope;

  @override
  Widget build(BuildContext context) {
    final _HomeStatPalette palette = scope.palette;
    return HomeBentoStatCard(
      label: scope.l10n.metadataTabCharacters,
      caption: scope.l10n.metadataCharacterCount(scope.counts.characterCount),
      icon: Symbols.face_3,
      backgroundColor: palette.charactersBackground,
      onBackgroundColor: palette.charactersForeground,
      borderRadius: const BorderRadius.all(Radius.circular(16)),
      emphasis: HomeBentoStatEmphasis.compact,
      layout: HomeBentoStatLayout.shortcut,
      onPressed: scope.onOpenCharacters,
    );
  }
}

class _TagStatCard extends StatelessWidget {
  const _TagStatCard({required this.scope});

  final _StatsScope scope;

  @override
  Widget build(BuildContext context) {
    final _HomeStatPalette palette = scope.palette;
    return HomeBentoStatCard(
      label: scope.l10n.homeStatTags,
      caption: scope.l10n.homeTagCount(scope.counts.tagCount),
      icon: Symbols.label,
      backgroundColor: palette.tagsBackground,
      onBackgroundColor: palette.tagsForeground,
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(32),
        topRight: Radius.circular(12),
        bottomLeft: Radius.circular(12),
        bottomRight: Radius.circular(32),
      ),
      minHeight: 108,
      layout: HomeBentoStatLayout.shortcut,
      onPressed: scope.onOpenTags,
    );
  }
}

class _HistoryStatCard extends StatelessWidget {
  const _HistoryStatCard({required this.scope});

  final _StatsScope scope;

  @override
  Widget build(BuildContext context) {
    final _HomeStatPalette palette = scope.palette;
    return HomeBentoStatCard(
      label: scope.l10n.historyTitle,
      caption: scope.l10n.homeHistoryCardCaption,
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
      onPressed: scope.onOpenHistory!,
    );
  }
}

class _TrashStatCard extends StatelessWidget {
  const _TrashStatCard({required this.scope});

  final _StatsScope scope;

  @override
  Widget build(BuildContext context) {
    final _HomeStatPalette palette = scope.palette;
    return HomeBentoStatCard(
      label: scope.l10n.navTrash,
      caption: scope.l10n.homeTrashCardCaption,
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
      onPressed: scope.onOpenTrash!,
    );
  }
}

class _ShortcutRow extends StatelessWidget {
  const _ShortcutRow({required this.scope});

  final _StatsScope scope;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(child: _HistoryStatCard(scope: scope)),
        SizedBox(width: scope.gap),
        Expanded(child: _TrashStatCard(scope: scope)),
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
      charactersBackground = scheme.secondaryContainer,
      charactersForeground = scheme.onSecondaryContainer,
      tagsBackground = scheme.emphasis,
      tagsForeground = scheme.onEmphasis,
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
