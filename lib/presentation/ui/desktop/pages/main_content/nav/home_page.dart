import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hentai_library/config/theme.dart';
import 'package:hentai_library/domain/entity/comic/series.dart';
import 'package:hentai_library/domain/entity/comic/tag.dart';
import 'package:hentai_library/presentation/dto/history_grid_item_dto.dart';
import 'package:hentai_library/presentation/providers/providers.dart';
import 'package:hentai_library/presentation/ui/shared/routing/app_router.dart';
import 'package:hentai_library/presentation/ui/shared/routing/reader_route_args.dart';
import 'package:hentai_library/presentation/ui/desktop/widgets/actions/ghost_button.dart';
import 'package:hentai_library/presentation/ui/desktop/widgets/overlays/dialog/scan_progress_dialog.dart';
import 'package:hentai_library/presentation/ui/desktop/widgets/element/card/reading_history_card.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

const double _kHomeContentMaxWidth = 1280;
const double _kHomeStatsStackBreakpointWidth = 720;
const double _kContinueReadingItemWidth = 304;
const double _kContinueReadingStripHeight = 138;
const double _kHeroStatCardRadius = 16;
const Duration _kHeroStatCardHoverDuration = Duration(milliseconds: 200);
const EdgeInsets _kHomePagePadding = EdgeInsets.symmetric(
  horizontal: 48,
  vertical: 16,
);

TextStyle _buildDesktopPageTitleStyle(ColorScheme colorScheme) {
  return TextStyle(
    color: colorScheme.textPrimary,
    fontSize: 26,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.4,
  );
}

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  void _onTapScanLibrary(BuildContext context, WidgetRef ref) {
    final bool running = ref.read(
      scanLibraryControllerProvider.select((s) => s.running),
    );
    if (!running) {
      ref.read(scanLibraryControllerProvider.notifier).start();
    }
    showDialog<void>(
      context: context,
      barrierColor: Colors.transparent,
      barrierDismissible: false,
      builder: (_) => const ScanProgressDialog(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppThemeTokens tokens = context.tokens;
    final int comicCount = ref.watch(
      libraryPageProvider.select((s) => s.rawList.length),
    );
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double maxW = constraints.maxWidth.clamp(
          0,
          _kHomeContentMaxWidth,
        );
        return SingleChildScrollView(
          padding: _kHomePagePadding,
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxW),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(context, ref),
                  SizedBox(height: tokens.spacing.xl + 12),
                  _buildHeroSection(context, ref, comicCount),
                  SizedBox(height: tokens.spacing.lg + 8),
                  _buildContinueReadingSection(context, ref),
                  SizedBox(height: tokens.spacing.xl + 8),
                  _buildShortcutEntries(context, ref),
                  SizedBox(height: tokens.spacing.xl * 4),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String _greetingPhraseForNow() {
    final int hour = DateTime.now().hour;
    if (hour < 5) {
      return '凌晨好';
    }
    if (hour < 9) {
      return '早上好';
    }
    if (hour < 12) {
      return '上午好';
    }
    if (hour < 14) {
      return '中午好';
    }
    if (hour < 18) {
      return '下午好';
    }
    if (hour < 23) {
      return '晚上好';
    }
    return '夜深了';
  }

  Widget _buildHeader(BuildContext context, WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final AppThemeTokens tokens = context.tokens;
    final ColorScheme cs = theme.colorScheme;
    final String greetingText = '${_greetingPhraseForNow()}，读者';
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        _HomeHeaderTextBlock(
          title: '首页',
          greetingText: greetingText,
          colorScheme: cs,
          tokens: tokens,
        ),
        _HomeHeaderActionBlock(
          colorScheme: cs,
          onRefresh: () {
            ref.read(libraryPageProvider.notifier).refreshStream();
          },
          onScan: () => _onTapScanLibrary(context, ref),
        ),
      ],
    );
  }

  Widget _buildHeroSection(
    BuildContext context,
    WidgetRef ref,
    int comicCount,
  ) {
    if (comicCount == 0) {
      return _buildEmptyLibraryHero(context, ref);
    }
    return _buildStatsCards(context, ref, comicCount);
  }

  Widget _buildEmptyLibraryHero(BuildContext context, WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final AppThemeTokens tokens = context.tokens;
    final ColorScheme cs = theme.colorScheme;
    final Color accent = cs.primary;
    final BorderSide actionBorderSide = BorderSide(color: cs.borderSubtle);
    final ButtonStyle outlinedActionStyle = OutlinedButton.styleFrom(
      foregroundColor: cs.textPrimary,
      side: actionBorderSide,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    );
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(_kHeroStatCardRadius),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            Color.alphaBlend(accent.withAlpha(22), cs.surface),
            Color.alphaBlend(accent.withAlpha(8), cs.surface),
            cs.surface,
          ],
          stops: const <double>[0, 0.45, 1],
        ),
        border: Border.all(
          color: Color.alphaBlend(accent.withAlpha(50), cs.borderSubtle),
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: cs.shadow.withAlpha(48),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(_kHeroStatCardRadius),
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
                                color: cs.textPrimary,
                              ),
                            ),
                            SizedBox(height: tokens.spacing.sm),
                            Text(
                              '请先在设置中添加库文件夹并扫描；若已配置，可检查选中路径或重新扫描。',
                              style: TextStyle(
                                fontSize: tokens.text.bodySm,
                                color: cs.textSecondary,
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
                        onPressed: () => _onTapScanLibrary(context, ref),
                        icon: const Icon(LucideIcons.scanSearch, size: 18),
                        label: const Text('扫描漫画库'),
                        style: FilledButton.styleFrom(
                          backgroundColor: cs.primary,
                          foregroundColor: cs.onPrimary,
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

  Widget _buildStatsCards(BuildContext context, WidgetRef ref, int comicCount) {
    final int historyCount = ref.watch(
      historyFeedViewProvider.select(
        (HistoryFeedViewData value) => value.totalCount,
      ),
    );
    final int seriesCount = ref
        .watch(allSeriesProvider)
        .maybeWhen(data: (List<Series> list) => list.length, orElse: () => 0);
    final int tagCount = ref
        .watch(allTagsProvider)
        .maybeWhen(data: (List<Tag> list) => list.length, orElse: () => 0);
    final ColorScheme cs = Theme.of(context).colorScheme;
    final Color accentLibrary = cs.primary;
    final Color accentSeries = cs.secondary;
    final Color accentTags = Color.lerp(cs.primary, cs.secondary, 0.45)!;
    final Color accentHistory = cs.inversePrimary;
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final bool stack =
            constraints.maxWidth < _kHomeStatsStackBreakpointWidth;
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
                valueText: '$historyCount',
                caption: historyCount == 0 ? '暂无历史' : '$historyCount 条',
                icon: LucideIcons.history,
                accentColor: accentHistory,
              ),
              Row(
                spacing: context.tokens.spacing.md,
                children: <Widget>[
                  Expanded(
                    child: _StatSummaryCard(
                      label: '系列',
                      valueText: '$seriesCount',
                      caption: '$seriesCount 个',
                      icon: LucideIcons.library,
                      accentColor: accentSeries,
                    ),
                  ),
                  Expanded(
                    child: _StatSummaryCard(
                      label: '标签',
                      valueText: '$tagCount',
                      caption: '$tagCount 个',
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
                valueText: '$seriesCount',
                caption: '$seriesCount 个系列',
                icon: LucideIcons.library,
                accentColor: accentSeries,
              ),
            ),
            Expanded(
              child: _StatSummaryCard(
                label: '标签',
                valueText: '$tagCount',
                caption: '$tagCount 个标签',
                icon: LucideIcons.tags,
                accentColor: accentTags,
              ),
            ),
            Expanded(
              child: _StatSummaryCard(
                label: '阅读记录',
                valueText: '$historyCount',
                caption: historyCount == 0 ? '暂无历史' : '$historyCount 条',
                icon: LucideIcons.history,
                accentColor: accentHistory,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildContinueReadingSection(BuildContext context, WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final AppThemeTokens tokens = context.tokens;
    final ColorScheme cs = theme.colorScheme;
    final bool loading = ref.watch(
      historyFeedViewProvider.select(
        (HistoryFeedViewData value) => value.isLoading,
      ),
    );
    final bool hasError = ref.watch(
      historyFeedViewProvider.select(
        (HistoryFeedViewData value) => value.hasError,
      ),
    );
    final List<HistoryGridItemDto> visible = ref.watch(
      historyFeedViewProvider.select(
        (HistoryFeedViewData value) => value.continueReadingItems,
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '继续阅读',
          style: TextStyle(
            fontSize: tokens.text.titleSm,
            fontWeight: FontWeight.w600,
            color: cs.textPrimary,
          ),
        ),
        SizedBox(height: tokens.spacing.sm),
        SizedBox(
          height: _kContinueReadingStripHeight + 8,
          child: _buildContinueReadingBody(
            context: context,
            loading: loading,
            hasError: hasError,
            visible: visible,
            tokens: tokens,
            cs: cs,
          ),
        ),
      ],
    );
  }

  Widget _buildContinueReadingBody({
    required BuildContext context,
    required bool loading,
    required bool hasError,
    required List<HistoryGridItemDto> visible,
    required AppThemeTokens tokens,
    required ColorScheme cs,
  }) {
    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (hasError) {
      return Center(
        child: Text(
          '加载失败',
          style: TextStyle(
            fontSize: tokens.text.bodySm,
            color: cs.textSecondary,
          ),
        ),
      );
    }
    if (visible.isEmpty) {
      return Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(LucideIcons.bookOpen, size: 20, color: cs.textTertiary),
            SizedBox(width: tokens.spacing.sm),
            Text(
              '暂无阅读记录，',
              style: TextStyle(
                fontSize: tokens.text.bodySm,
                color: cs.textSecondary,
              ),
            ),
            TextButton(
              onPressed: () => context.go('/local'),
              child: const Text('去漫画库'),
            ),
          ],
        ),
      );
    }
    return ListView.separated(
      scrollDirection: Axis.horizontal,
      itemCount: visible.length,
      separatorBuilder: (BuildContext context, int index) =>
          SizedBox(width: tokens.spacing.md),
      itemBuilder: (BuildContext context, int index) {
        final HistoryGridItemDto item = visible[index];
        return SizedBox(
          width: _kContinueReadingItemWidth,
          height: _kContinueReadingStripHeight,
          child: item.map(
            comic: (ComicHistoryGridItemDto c) => ReadingHistoryCard.comic(
              comicId: c.comicId,
              title: c.title,
              lastReadTime: c.lastReadTime,
              pageIndex: c.pageIndex,
              onTap: () => appRouter.pushNamed(
                ReaderRouteArgs.readerRouteName,
                queryParameters: ReaderRouteArgs(
                  comicId: c.comicId,
                  readType: ReaderRouteArgs.readTypeComic,
                ).toQueryParameters(),
              ),
            ),
            series: (SeriesHistoryGridItemDto s) => ReadingHistoryCard.series(
              seriesName: s.seriesName,
              lastReadComicId: s.lastReadComicId,
              lastReadTime: s.lastReadTime,
              pageIndex: s.pageIndex,
              lastReadComicOrder: s.lastReadComicOrder,
              onTap: () => appRouter.pushNamed(
                ReaderRouteArgs.readerRouteName,
                queryParameters: ReaderRouteArgs(
                  comicId: s.lastReadComicId,
                  readType: ReaderRouteArgs.readTypeSeries,
                  seriesName: s.seriesName,
                ).toQueryParameters(),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildShortcutEntries(BuildContext context, WidgetRef ref) {
    final AppThemeTokens tokens = context.tokens;
    final ColorScheme cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '快捷入口',
          style: TextStyle(
            fontSize: tokens.text.titleSm,
            fontWeight: FontWeight.w600,
            color: cs.textPrimary,
          ),
        ),
        SizedBox(height: tokens.spacing.sm),
        Wrap(
          spacing: tokens.spacing.md,
          runSpacing: tokens.spacing.md,
          children: [
            _ShortcutTile(
              icon: LucideIcons.library,
              label: '漫画库',
              onTap: () => context.go('/local'),
              colorScheme: cs,
              tokens: tokens,
            ),
            _ShortcutTile(
              icon: LucideIcons.history,
              label: '阅读历史',
              onTap: () => context.go('/history'),
              colorScheme: cs,
              tokens: tokens,
            ),
            _ShortcutTile(
              icon: LucideIcons.layers,
              label: '资料管理',
              onTap: () => context.go('/metadata?tab=tags'),
              colorScheme: cs,
              tokens: tokens,
            ),
            _ShortcutTile(
              icon: LucideIcons.folderTree,
              label: '选中路径',
              onTap: () => context.go('/paths'),
              colorScheme: cs,
              tokens: tokens,
            ),
            _ShortcutTile(
              icon: LucideIcons.scanSearch,
              label: '扫描漫画库',
              onTap: () => _onTapScanLibrary(context, ref),
              colorScheme: cs,
              tokens: tokens,
            ),
            _ShortcutTile(
              icon: LucideIcons.settings,
              label: '设置',
              onTap: () => context.go('/settings'),
              colorScheme: cs,
              tokens: tokens,
            ),
          ],
        ),
      ],
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
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final AppThemeTokens tokens = context.tokens;
    final ColorScheme cs = theme.colorScheme;
    final Color accent = widget.accentColor;
    final Curve curve = Curves.easeOutCubic;
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: _kHeroStatCardHoverDuration,
        curve: curve,
        transformAlignment: Alignment.bottomCenter,
        transform: Matrix4.identity()..translate(0.0, _isHovered ? -3.0 : 0.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(_kHeroStatCardRadius),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: <Color>[
              Color.alphaBlend(accent.withAlpha(26), cs.surface),
              Color.alphaBlend(accent.withAlpha(8), cs.surface),
              cs.surface,
            ],
            stops: const <double>[0, 0.38, 1],
          ),
          border: Border.all(
            color: Color.alphaBlend(accent.withAlpha(52), cs.borderSubtle),
          ),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: cs.shadow.withAlpha(36),
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
          borderRadius: BorderRadius.circular(_kHeroStatCardRadius),
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
                                cs.textTertiary,
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
                              color: cs.textPrimary,
                            ),
                          ),
                          SizedBox(height: tokens.spacing.sm - 1),
                          Text(
                            widget.caption,
                            style: TextStyle(
                              fontSize: tokens.text.bodySm,
                              color: cs.textSecondary,
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                    AnimatedContainer(
                      duration: _kHeroStatCardHoverDuration,
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

class _ShortcutTile extends StatefulWidget {
  const _ShortcutTile({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.colorScheme,
    required this.tokens,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final ColorScheme colorScheme;
  final AppThemeTokens tokens;

  @override
  State<_ShortcutTile> createState() => _ShortcutTileState();
}

class _ShortcutTileState extends State<_ShortcutTile> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = widget.colorScheme;
    final AppThemeTokens tokens = widget.tokens;
    const Duration duration = Duration(milliseconds: 180);
    final Curve curve = Curves.easeOutCubic;
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(12),
          hoverColor: cs.primary.withAlpha(20),
          splashColor: cs.primary.withAlpha(28),
          highlightColor: cs.primary.withAlpha(12),
          child: AnimatedContainer(
            duration: duration,
            curve: curve,
            width: 120,
            padding: EdgeInsets.fromLTRB(
              tokens.spacing.sm + 2,
              tokens.spacing.md + 2,
              tokens.spacing.sm + 2,
              tokens.spacing.md,
            ),
            decoration: BoxDecoration(
              color: _isHovered ? cs.surfaceContainerHighest : cs.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _isHovered ? cs.primary.withAlpha(100) : cs.borderSubtle,
                width: 1,
              ),
              boxShadow: _isHovered
                  ? <BoxShadow>[
                      BoxShadow(
                        color: cs.shadow.withAlpha(40),
                        blurRadius: 14,
                        offset: const Offset(0, 6),
                      ),
                    ]
                  : const <BoxShadow>[],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedContainer(
                  duration: duration,
                  curve: curve,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: cs.primary.withAlpha(_isHovered ? 26 : 16),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: cs.primary.withAlpha(_isHovered ? 55 : 35),
                    ),
                  ),
                  child: Icon(widget.icon, size: 22, color: cs.primary),
                ),
                SizedBox(height: tokens.spacing.sm + 2),
                Text(
                  widget.label,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: tokens.text.bodySm,
                    fontWeight: FontWeight.w600,
                    color: cs.textPrimary,
                    height: 1.25,
                    letterSpacing: -0.1,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HomeHeaderTextBlock extends StatelessWidget {
  const _HomeHeaderTextBlock({
    required this.title,
    required this.greetingText,
    required this.colorScheme,
    required this.tokens,
  });

  final String title;
  final String greetingText;
  final ColorScheme colorScheme;
  final AppThemeTokens tokens;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(title, style: _buildDesktopPageTitleStyle(colorScheme)),
        SizedBox(height: tokens.spacing.xs),
        Text(
          greetingText,
          style: TextStyle(color: colorScheme.textTertiary, fontSize: 13),
        ),
      ],
    );
  }
}

class _HomeHeaderActionBlock extends StatelessWidget {
  const _HomeHeaderActionBlock({
    required this.colorScheme,
    required this.onRefresh,
    required this.onScan,
  });

  final ColorScheme colorScheme;
  final VoidCallback onRefresh;
  final VoidCallback onScan;

  @override
  Widget build(BuildContext context) {
    return Row(
      spacing: 8,
      children: <Widget>[
        GhostButton.icon(
          icon: LucideIcons.refreshCw,
          tooltip: '',
          semanticLabel: '刷新漫画库列表',
          iconSize: 16,
          size: 24,
          borderRadius: 10,
          foregroundColor: colorScheme.iconDefault,
          hoverColor: colorScheme.surfaceContainerHighest,
          overlayColor: colorScheme.primary.withAlpha(32),
          delayTooltipThreeSeconds: false,
          onPressed: onRefresh,
        ),
        FilledButton.icon(
          onPressed: onScan,
          icon: const Icon(LucideIcons.scanSearch, size: 18),
          label: const Text('扫描漫画库'),
          style: FilledButton.styleFrom(
            backgroundColor: colorScheme.primary,
            foregroundColor: colorScheme.onPrimary,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ],
    );
  }
}
