import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hentai_library/core/l10n/app_localizations.dart';
import 'package:hentai_library/core/l10n/app_localizations_x.dart';
import 'package:hentai_library/ui/core/theme/theme.dart';
import 'package:hentai_library/domain/models/read_models/home_page_read_models.dart';
import 'package:hentai_library/ui/providers.dart';
import 'package:hentai_library/ui/features/shell/views/home_page/widgets/home_page_constants.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class HomePageHeroSection extends ConsumerWidget {
  const HomePageHeroSection({
    super.key,
    required this.layoutTier,
    required this.comicCount,
    required this.isLibraryEmpty,
    required this.onScan,
    required this.enableHeavyStats,
  });

  final HomePageLayoutTier layoutTier;
  final int comicCount;
  final bool isLibraryEmpty;
  final VoidCallback onScan;
  final bool enableHeavyStats;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (isLibraryEmpty) {
      return _EmptyLibraryHero(layoutTier: layoutTier, onScan: onScan);
    }
    if (!enableHeavyStats) {
      return _StatsCardsPlaceholder(
        layoutTier: layoutTier,
        comicCount: comicCount,
      );
    }
    return _StatsCards(layoutTier: layoutTier, comicCount: comicCount);
  }
}

class _EmptyLibraryHero extends StatelessWidget {
  const _EmptyLibraryHero({required this.layoutTier, required this.onScan});

  final HomePageLayoutTier layoutTier;
  final VoidCallback onScan;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final AppThemeTokens tokens = context.tokens;
    final ColorScheme colorScheme = theme.colorScheme;
    final l10n = context.l10n;
    final Color accent = colorScheme.primary;
    final BorderSide actionBorderSide = BorderSide(
      color: colorScheme.hentai.borderSubtle,
    );
    final ButtonStyle outlinedActionStyle = OutlinedButton.styleFrom(
      foregroundColor: colorScheme.hentai.textPrimary,
      side: actionBorderSide,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    );
    final Widget iconBadge = DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[accent.withAlpha(36), accent.withAlpha(14)],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accent.withAlpha(55)),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: accent.withAlpha(28),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Icon(LucideIcons.folderOpen, size: 32, color: accent),
      ),
    );
    final Widget copyBlock = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          l10n.homeEmptyTitle,
          style: TextStyle(
            fontSize: tokens.text.titleMd,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
            color: colorScheme.hentai.textPrimary,
          ),
        ),
        SizedBox(height: tokens.spacing.sm),
        Text(
          l10n.homeEmptyHint,
          style: TextStyle(
            fontSize: tokens.text.bodySm,
            color: colorScheme.hentai.textSecondary,
            height: 1.5,
          ),
        ),
      ],
    );
    final Widget introBlock = layoutTier == HomePageLayoutTier.compact
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              iconBadge,
              SizedBox(height: tokens.spacing.md),
              copyBlock,
            ],
          )
        : Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              iconBadge,
              SizedBox(width: tokens.spacing.md + 4),
              Expanded(child: copyBlock),
            ],
          );
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(heroStatCardRadius),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            Color.alphaBlend(accent.withAlpha(22), colorScheme.surface),
            Color.alphaBlend(accent.withAlpha(8), colorScheme.surface),
            colorScheme.surface,
          ],
          stops: const <double>[0, 0.45, 1],
        ),
        border: Border.all(
          color: Color.alphaBlend(
            accent.withAlpha(50),
            colorScheme.hentai.borderSubtle,
          ),
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: colorScheme.shadow.withAlpha(48),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(heroStatCardRadius),
        child: Stack(
          children: <Widget>[
            Positioned(
              right: -20,
              top: -28,
              child: Icon(
                LucideIcons.libraryBig,
                size: 140,
                color: accent.withAlpha(14),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(tokens.spacing.lg + 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  introBlock,
                  SizedBox(height: tokens.spacing.lg + 4),
                  Wrap(
                    spacing: tokens.spacing.sm,
                    runSpacing: tokens.spacing.sm,
                    children: <Widget>[
                      FilledButton.icon(
                        onPressed: onScan,
                        icon: const Icon(LucideIcons.scanSearch, size: 18),
                        label: Text(l10n.homeScanLibrary),
                        style: FilledButton.styleFrom(
                          backgroundColor: colorScheme.primary,
                          foregroundColor: colorScheme.onPrimary,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 11,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          elevation: 0,
                        ),
                      ),
                      OutlinedButton.icon(
                        onPressed: () => context.go('/paths'),
                        icon: const Icon(LucideIcons.folderTree, size: 18),
                        label: Text(l10n.pathsTitle),
                        style: outlinedActionStyle,
                      ),
                      OutlinedButton.icon(
                        onPressed: () => context.go('/settings'),
                        icon: const Icon(LucideIcons.settings, size: 18),
                        label: Text(l10n.navSettings),
                        style: outlinedActionStyle,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

typedef _HomeStatCardData = ({
  String label,
  String valueText,
  String caption,
  IconData icon,
  Color accentColor,
});

class _StatsCards extends ConsumerWidget {
  const _StatsCards({required this.layoutTier, required this.comicCount});

  final HomePageLayoutTier layoutTier;
  final int comicCount;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<HomePageCounts> homeCounts = ref.watch(
      homePageCountsStreamProvider,
    );
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final AppLocalizations l10n = context.l10n;
    final _HomeStatAccentColors accents = _HomeStatAccentColors(colorScheme);
    return homeCounts.when(
      data: (HomePageCounts c) => _HomeStatsCardLayout(
        layoutTier: layoutTier,
        comicCard: _buildStatCard(context, (
          label: l10n.libraryTitle,
          valueText: '${c.comicCount}',
          caption: l10n.homeComicTotal(c.comicCount),
          icon: LucideIcons.bookImage,
          accentColor: accents.library,
        )),
        seriesCard: _buildStatCard(context, (
          label: l10n.homeStatSeries,
          valueText: '${c.seriesCount}',
          caption: l10n.homeSeriesCount(c.seriesCount),
          icon: LucideIcons.library,
          accentColor: accents.series,
        )),
        tagsCard: _buildStatCard(context, (
          label: l10n.homeStatTags,
          valueText: '${c.tagCount}',
          caption: l10n.homeTagCount(c.tagCount),
          icon: LucideIcons.tags,
          accentColor: accents.tags,
        )),
        authorCard: _buildStatCard(context, (
          label: l10n.homeStatAuthors,
          valueText: '${c.authorCount}',
          caption: c.authorCount == 0
              ? l10n.homeNoAuthors
              : l10n.homeAuthorCount(c.authorCount),
          icon: LucideIcons.penLine,
          accentColor: accents.authors,
        )),
      ),
      loading: () => _HomeStatsCardLayout(
        layoutTier: layoutTier,
        comicCard: _buildStatCard(context, (
          label: l10n.libraryTitle,
          valueText: '$comicCount',
          caption: l10n.homeComicTotal(comicCount),
          icon: LucideIcons.bookImage,
          accentColor: accents.library,
        )),
        seriesCard: _buildStatCard(context, (
          label: l10n.homeStatSeries,
          valueText: '--',
          caption: l10n.shellLoading,
          icon: LucideIcons.library,
          accentColor: accents.series,
        )),
        tagsCard: _buildStatCard(context, (
          label: l10n.homeStatTags,
          valueText: '--',
          caption: l10n.shellLoading,
          icon: LucideIcons.tags,
          accentColor: accents.tags,
        )),
        authorCard: _buildStatCard(context, (
          label: l10n.homeStatAuthors,
          valueText: '--',
          caption: l10n.shellLoading,
          icon: LucideIcons.penLine,
          accentColor: accents.authors,
        )),
      ),
      error: (Object error, StackTrace stackTrace) => _HomeStatsCardLayout(
        layoutTier: layoutTier,
        comicCard: _buildStatCard(context, (
          label: l10n.libraryTitle,
          valueText: '$comicCount',
          caption: l10n.homeComicTotal(comicCount),
          icon: LucideIcons.bookImage,
          accentColor: accents.library,
        )),
        seriesCard: _buildStatCard(context, (
          label: l10n.homeStatSeries,
          valueText: '--',
          caption: l10n.shellLoadFailed,
          icon: LucideIcons.library,
          accentColor: accents.series,
        )),
        tagsCard: _buildStatCard(context, (
          label: l10n.homeStatTags,
          valueText: '--',
          caption: l10n.shellLoadFailed,
          icon: LucideIcons.tags,
          accentColor: accents.tags,
        )),
        authorCard: _buildStatCard(context, (
          label: l10n.homeStatAuthors,
          valueText: '--',
          caption: l10n.shellLoadFailed,
          icon: LucideIcons.penLine,
          accentColor: accents.authors,
        )),
      ),
    );
  }
}

class _StatsCardsPlaceholder extends StatelessWidget {
  const _StatsCardsPlaceholder({
    required this.layoutTier,
    required this.comicCount,
  });

  final HomePageLayoutTier layoutTier;
  final int comicCount;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final AppLocalizations l10n = context.l10n;
    final _HomeStatAccentColors accents = _HomeStatAccentColors(colorScheme);
    return _HomeStatsCardLayout(
      layoutTier: layoutTier,
      comicCard: _buildStatCard(context, (
        label: l10n.libraryTitle,
        valueText: '$comicCount',
        caption: l10n.homeComicTotal(comicCount),
        icon: LucideIcons.bookImage,
        accentColor: accents.library,
      )),
      seriesCard: _buildStatCard(context, (
        label: l10n.homeStatSeries,
        valueText: '--',
        caption: l10n.shellLoading,
        icon: LucideIcons.library,
        accentColor: accents.series,
      )),
      tagsCard: _buildStatCard(context, (
        label: l10n.homeStatTags,
        valueText: '--',
        caption: l10n.shellLoading,
        icon: LucideIcons.tags,
        accentColor: accents.tags,
      )),
      authorCard: _buildStatCard(context, (
        label: l10n.homeStatAuthors,
        valueText: '--',
        caption: l10n.shellLoading,
        icon: LucideIcons.penLine,
        accentColor: accents.authors,
      )),
    );
  }
}

class _HomeStatAccentColors {
  _HomeStatAccentColors(ColorScheme colorScheme)
    : library = colorScheme.primary,
      series = colorScheme.secondary,
      tags = Color.lerp(colorScheme.primary, colorScheme.secondary, 0.45)!,
      authors = colorScheme.inversePrimary;

  final Color library;
  final Color series;
  final Color tags;
  final Color authors;
}

Widget _buildStatCard(BuildContext context, _HomeStatCardData data) {
  return _StatSummaryCard(
    label: data.label,
    valueText: data.valueText,
    caption: data.caption,
    icon: data.icon,
    accentColor: data.accentColor,
  );
}

class _HomeStatsCardLayout extends StatelessWidget {
  const _HomeStatsCardLayout({
    required this.layoutTier,
    required this.comicCard,
    required this.seriesCard,
    required this.tagsCard,
    required this.authorCard,
  });

  final HomePageLayoutTier layoutTier;
  final Widget comicCard;
  final Widget seriesCard;
  final Widget tagsCard;
  final Widget authorCard;

  @override
  Widget build(BuildContext context) {
    final double gap = context.tokens.spacing.md;
    return switch (layoutTier) {
      HomePageLayoutTier.compact => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: gap,
        children: <Widget>[comicCard, authorCard, seriesCard, tagsCard],
      ),
      HomePageLayoutTier.medium => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: gap,
        children: <Widget>[
          Row(
            spacing: gap,
            children: <Widget>[
              Expanded(child: comicCard),
              Expanded(child: seriesCard),
            ],
          ),
          Row(
            spacing: gap,
            children: <Widget>[
              Expanded(child: authorCard),
              Expanded(child: tagsCard),
            ],
          ),
        ],
      ),
      HomePageLayoutTier.expanded => Row(
        spacing: gap,
        children: <Widget>[
          Expanded(child: comicCard),
          Expanded(child: seriesCard),
          Expanded(child: tagsCard),
          Expanded(child: authorCard),
        ],
      ),
    };
  }
}

class _StatSummaryCard extends StatefulWidget {
  const _StatSummaryCard({
    required this.label,
    required this.valueText,
    required this.caption,
    required this.icon,
    required this.accentColor,
  });

  final String label;
  final String valueText;
  final String caption;
  final IconData icon;
  final Color accentColor;

  @override
  State<_StatSummaryCard> createState() => _StatSummaryCardState();
}

class _StatSummaryCardState extends State<_StatSummaryCard> {
  bool isHovered = false;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final AppThemeTokens tokens = context.tokens;
    final ColorScheme colorScheme = theme.colorScheme;
    final Color accent = widget.accentColor;
    final Curve curve = Curves.easeOutCubic;
    return MouseRegion(
      onEnter: (_) => setState(() => isHovered = true),
      onExit: (_) => setState(() => isHovered = false),
      child: AnimatedContainer(
        duration: heroStatCardHoverDuration,
        curve: curve,
        transformAlignment: Alignment.bottomCenter,
        transform: Matrix4.identity()..translate(0.0, isHovered ? -3.0 : 0.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(heroStatCardRadius),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: <Color>[
              Color.alphaBlend(accent.withAlpha(26), colorScheme.surface),
              Color.alphaBlend(accent.withAlpha(8), colorScheme.surface),
              colorScheme.surface,
            ],
            stops: const <double>[0, 0.38, 1],
          ),
          border: Border.all(
            color: Color.alphaBlend(
              accent.withAlpha(52),
              colorScheme.hentai.borderSubtle,
            ),
          ),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: colorScheme.shadow.withAlpha(36),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
            BoxShadow(
              color: accent.withAlpha(14),
              blurRadius: 0,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(heroStatCardRadius),
          child: Stack(
            children: <Widget>[
              Positioned(
                right: -8,
                bottom: -12,
                child: Icon(widget.icon, size: 88, color: accent.withAlpha(16)),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(
                  tokens.spacing.lg + 4,
                  tokens.spacing.lg + 6,
                  tokens.spacing.lg + 4,
                  tokens.spacing.lg + 4,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            widget.label,
                            style: TextStyle(
                              fontSize: tokens.text.labelXs,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.8,
                              color: Color.alphaBlend(
                                accent.withAlpha(200),
                                colorScheme.hentai.textTertiary,
                              ),
                            ),
                          ),
                          SizedBox(height: tokens.spacing.sm + 2),
                          Text(
                            widget.valueText,
                            style: TextStyle(
                              fontSize: tokens.text.titleLg + 6,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.8,
                              height: 1.05,
                              color: colorScheme.hentai.textPrimary,
                            ),
                          ),
                          SizedBox(height: tokens.spacing.sm - 1),
                          Text(
                            widget.caption,
                            style: TextStyle(
                              fontSize: tokens.text.bodySm,
                              color: colorScheme.hentai.textSecondary,
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                    AnimatedContainer(
                      duration: heroStatCardHoverDuration,
                      curve: curve,
                      padding: const EdgeInsets.all(11),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: <Color>[
                            accent.withAlpha(30),
                            accent.withAlpha(14),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: accent.withAlpha(58)),
                        boxShadow: const <BoxShadow>[],
                      ),
                      child: Icon(widget.icon, size: 28, color: accent),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
