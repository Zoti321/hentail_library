import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hentai_library/presentation/theme/theme.dart';
import 'package:hentai_library/database/dao/home_page_dao_types.dart';
import 'package:hentai_library/presentation/providers/providers.dart';
import 'package:hentai_library/presentation/ui/desktop/pages/main_content/nav/home_page/widgets/home_page_constants.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class HomePageHeroSection extends ConsumerWidget {
  const HomePageHeroSection({
    super.key,
    required this.comicCount,
    required this.isLibraryEmpty,
    required this.onScan,
    required this.enableHeavyStats,
  });

  final int comicCount;
  final bool isLibraryEmpty;
  final VoidCallback onScan;
  final bool enableHeavyStats;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (isLibraryEmpty) {
      return _EmptyLibraryHero(onScan: onScan);
    }
    if (!enableHeavyStats) {
      return _StatsCardsPlaceholder(comicCount: comicCount);
    }
    return _StatsCards(comicCount: comicCount);
  }
}

class _EmptyLibraryHero extends StatelessWidget {
  const _EmptyLibraryHero({required this.onScan});

  final VoidCallback onScan;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final AppThemeTokens tokens = context.tokens;
    final ColorScheme colorScheme = theme.colorScheme;
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
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: <Color>[
                              accent.withAlpha(36),
                              accent.withAlpha(14),
                            ],
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
                          child: Icon(
                            LucideIcons.folderOpen,
                            size: 32,
                            color: accent,
                          ),
                        ),
                      ),
                      SizedBox(width: tokens.spacing.md + 4),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              '尚未导入漫画',
                              style: TextStyle(
                                fontSize: tokens.text.titleMd,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.3,
                                color: colorScheme.hentai.textPrimary,
                              ),
                            ),
                            SizedBox(height: tokens.spacing.sm),
                            Text(
                              '请先在设置中添加库文件夹并扫描；若已配置，可检查选中路径或重新扫描。',
                              style: TextStyle(
                                fontSize: tokens.text.bodySm,
                                color: colorScheme.hentai.textSecondary,
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: tokens.spacing.lg + 4),
                  Wrap(
                    spacing: tokens.spacing.sm,
                    runSpacing: tokens.spacing.sm,
                    children: <Widget>[
                      FilledButton.icon(
                        onPressed: onScan,
                        icon: const Icon(LucideIcons.scanSearch, size: 18),
                        label: const Text('扫描漫画库'),
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
                        label: const Text('选中路径'),
                        style: outlinedActionStyle,
                      ),
                      OutlinedButton.icon(
                        onPressed: () => context.go('/settings'),
                        icon: const Icon(LucideIcons.settings, size: 18),
                        label: const Text('设置'),
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

class _StatsCards extends ConsumerWidget {
  const _StatsCards({required this.comicCount});

  final int comicCount;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<HomePageCounts> homeCounts = ref.watch(
      homePageCountsStreamProvider,
    );
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final Color accentLibrary = colorScheme.primary;
    final Color accentSeries = colorScheme.secondary;
    final Color accentTags = Color.lerp(
      colorScheme.primary,
      colorScheme.secondary,
      0.45,
    )!;
    final Color accentHistory = colorScheme.inversePrimary;
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final bool stack = constraints.maxWidth < homeStatsStackBreakpointWidth;
        return homeCounts.when(
          data: (HomePageCounts c) {
            if (stack) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: context.tokens.spacing.md,
                children: <Widget>[
                  _StatSummaryCard(
                    label: '漫画库',
                    valueText: '${c.comicCount}',
                    caption: '共 ${c.comicCount} 本',
                    icon: LucideIcons.bookImage,
                    accentColor: accentLibrary,
                  ),
                  _StatSummaryCard(
                    label: '阅读记录',
                    valueText: '${c.readingRecordCount}',
                    caption: c.readingRecordCount == 0
                        ? '暂无历史'
                        : '${c.readingRecordCount} 条',
                    icon: LucideIcons.history,
                    accentColor: accentHistory,
                  ),
                  Row(
                    spacing: context.tokens.spacing.md,
                    children: <Widget>[
                      Expanded(
                        child: _StatSummaryCard(
                          label: '系列',
                          valueText: '${c.seriesCount}',
                          caption: '${c.seriesCount} 个',
                          icon: LucideIcons.library,
                          accentColor: accentSeries,
                        ),
                      ),
                      Expanded(
                        child: _StatSummaryCard(
                          label: '标签',
                          valueText: '${c.tagCount}',
                          caption: '${c.tagCount} 个',
                          icon: LucideIcons.tags,
                          accentColor: accentTags,
                        ),
                      ),
                    ],
                  ),
                ],
              );
            }
            return Row(
              spacing: context.tokens.spacing.md,
              children: <Widget>[
                Expanded(
                  child: _StatSummaryCard(
                    label: '漫画库',
                    valueText: '${c.comicCount}',
                    caption: '共 ${c.comicCount} 本',
                    icon: LucideIcons.bookImage,
                    accentColor: accentLibrary,
                  ),
                ),
                Expanded(
                  child: _StatSummaryCard(
                    label: '系列',
                    valueText: '${c.seriesCount}',
                    caption: '${c.seriesCount} 个系列',
                    icon: LucideIcons.library,
                    accentColor: accentSeries,
                  ),
                ),
                Expanded(
                  child: _StatSummaryCard(
                    label: '标签',
                    valueText: '${c.tagCount}',
                    caption: '${c.tagCount} 个标签',
                    icon: LucideIcons.tags,
                    accentColor: accentTags,
                  ),
                ),
                Expanded(
                  child: _StatSummaryCard(
                    label: '阅读记录',
                    valueText: '${c.readingRecordCount}',
                    caption: c.readingRecordCount == 0
                        ? '暂无历史'
                        : '${c.readingRecordCount} 条',
                    icon: LucideIcons.history,
                    accentColor: accentHistory,
                  ),
                ),
              ],
            );
          },
          loading: () {
            if (stack) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: context.tokens.spacing.md,
                children: <Widget>[
                  _StatSummaryCard(
                    label: '漫画库',
                    valueText: '$comicCount',
                    caption: '共 $comicCount 本',
                    icon: LucideIcons.bookImage,
                    accentColor: accentLibrary,
                  ),
                  _StatSummaryCard(
                    label: '阅读记录',
                    valueText: '--',
                    caption: '加载中…',
                    icon: LucideIcons.history,
                    accentColor: accentHistory,
                  ),
                  Row(
                    spacing: context.tokens.spacing.md,
                    children: <Widget>[
                      Expanded(
                        child: _StatSummaryCard(
                          label: '系列',
                          valueText: '--',
                          caption: '加载中…',
                          icon: LucideIcons.library,
                          accentColor: accentSeries,
                        ),
                      ),
                      Expanded(
                        child: _StatSummaryCard(
                          label: '标签',
                          valueText: '--',
                          caption: '加载中…',
                          icon: LucideIcons.tags,
                          accentColor: accentTags,
                        ),
                      ),
                    ],
                  ),
                ],
              );
            }
            return Row(
              spacing: context.tokens.spacing.md,
              children: <Widget>[
                Expanded(
                  child: _StatSummaryCard(
                    label: '漫画库',
                    valueText: '$comicCount',
                    caption: '共 $comicCount 本',
                    icon: LucideIcons.bookImage,
                    accentColor: accentLibrary,
                  ),
                ),
                Expanded(
                  child: _StatSummaryCard(
                    label: '系列',
                    valueText: '--',
                    caption: '加载中…',
                    icon: LucideIcons.library,
                    accentColor: accentSeries,
                  ),
                ),
                Expanded(
                  child: _StatSummaryCard(
                    label: '标签',
                    valueText: '--',
                    caption: '加载中…',
                    icon: LucideIcons.tags,
                    accentColor: accentTags,
                  ),
                ),
                Expanded(
                  child: _StatSummaryCard(
                    label: '阅读记录',
                    valueText: '--',
                    caption: '加载中…',
                    icon: LucideIcons.history,
                    accentColor: accentHistory,
                  ),
                ),
              ],
            );
          },
          error: (Object error, StackTrace stackTrace) {
            if (stack) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: context.tokens.spacing.md,
                children: <Widget>[
                  _StatSummaryCard(
                    label: '漫画库',
                    valueText: '$comicCount',
                    caption: '共 $comicCount 本',
                    icon: LucideIcons.bookImage,
                    accentColor: accentLibrary,
                  ),
                  _StatSummaryCard(
                    label: '阅读记录',
                    valueText: '--',
                    caption: '加载失败',
                    icon: LucideIcons.history,
                    accentColor: accentHistory,
                  ),
                  Row(
                    spacing: context.tokens.spacing.md,
                    children: <Widget>[
                      Expanded(
                        child: _StatSummaryCard(
                          label: '系列',
                          valueText: '--',
                          caption: '加载失败',
                          icon: LucideIcons.library,
                          accentColor: accentSeries,
                        ),
                      ),
                      Expanded(
                        child: _StatSummaryCard(
                          label: '标签',
                          valueText: '--',
                          caption: '加载失败',
                          icon: LucideIcons.tags,
                          accentColor: accentTags,
                        ),
                      ),
                    ],
                  ),
                ],
              );
            }
            return Row(
              spacing: context.tokens.spacing.md,
              children: <Widget>[
                Expanded(
                  child: _StatSummaryCard(
                    label: '漫画库',
                    valueText: '$comicCount',
                    caption: '共 $comicCount 本',
                    icon: LucideIcons.bookImage,
                    accentColor: accentLibrary,
                  ),
                ),
                Expanded(
                  child: _StatSummaryCard(
                    label: '系列',
                    valueText: '--',
                    caption: '加载失败',
                    icon: LucideIcons.library,
                    accentColor: accentSeries,
                  ),
                ),
                Expanded(
                  child: _StatSummaryCard(
                    label: '标签',
                    valueText: '--',
                    caption: '加载失败',
                    icon: LucideIcons.tags,
                    accentColor: accentTags,
                  ),
                ),
                Expanded(
                  child: _StatSummaryCard(
                    label: '阅读记录',
                    valueText: '--',
                    caption: '加载失败',
                    icon: LucideIcons.history,
                    accentColor: accentHistory,
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _StatsCardsPlaceholder extends StatelessWidget {
  const _StatsCardsPlaceholder({required this.comicCount});

  final int comicCount;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final Color accentLibrary = colorScheme.primary;
    final Color accentSeries = colorScheme.secondary;
    final Color accentTags = Color.lerp(
      colorScheme.primary,
      colorScheme.secondary,
      0.45,
    )!;
    final Color accentHistory = colorScheme.inversePrimary;
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final bool stack = constraints.maxWidth < homeStatsStackBreakpointWidth;
        if (stack) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: context.tokens.spacing.md,
            children: <Widget>[
              _StatSummaryCard(
                label: '漫画库',
                valueText: '$comicCount',
                caption: '共 $comicCount 本',
                icon: LucideIcons.bookImage,
                accentColor: accentLibrary,
              ),
              _StatSummaryCard(
                label: '阅读记录',
                valueText: '--',
                caption: '加载中…',
                icon: LucideIcons.history,
                accentColor: accentHistory,
              ),
              Row(
                spacing: context.tokens.spacing.md,
                children: <Widget>[
                  Expanded(
                    child: _StatSummaryCard(
                      label: '系列',
                      valueText: '--',
                      caption: '加载中…',
                      icon: LucideIcons.library,
                      accentColor: accentSeries,
                    ),
                  ),
                  Expanded(
                    child: _StatSummaryCard(
                      label: '标签',
                      valueText: '--',
                      caption: '加载中…',
                      icon: LucideIcons.tags,
                      accentColor: accentTags,
                    ),
                  ),
                ],
              ),
            ],
          );
        }
        return Row(
          spacing: context.tokens.spacing.md,
          children: <Widget>[
            Expanded(
              child: _StatSummaryCard(
                label: '漫画库',
                valueText: '$comicCount',
                caption: '共 $comicCount 本',
                icon: LucideIcons.bookImage,
                accentColor: accentLibrary,
              ),
            ),
            Expanded(
              child: _StatSummaryCard(
                label: '系列',
                valueText: '--',
                caption: '加载中…',
                icon: LucideIcons.library,
                accentColor: accentSeries,
              ),
            ),
            Expanded(
              child: _StatSummaryCard(
                label: '标签',
                valueText: '--',
                caption: '加载中…',
                icon: LucideIcons.tags,
                accentColor: accentTags,
              ),
            ),
            Expanded(
              child: _StatSummaryCard(
                label: '阅读记录',
                valueText: '--',
                caption: '加载中…',
                icon: LucideIcons.history,
                accentColor: accentHistory,
              ),
            ),
          ],
        );
      },
    );
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
