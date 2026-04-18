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
import 'package:hentai_library/presentation/ui/desktop/widgets/button/ghost_button.dart';
import 'package:hentai_library/presentation/ui/desktop/widgets/dialog/scan_progress_dialog.dart';
import 'package:hentai_library/presentation/ui/desktop/widgets/element/reading_history_card.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

const double _kHomeContentMaxWidth = 1280;
const double _kHomeStatsStackBreakpointWidth = 720;
const double _kContinueReadingItemWidth = 304;
const double _kContinueReadingStripHeight = 138;

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
    return SafeArea(
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final double maxW = constraints.maxWidth.clamp(
            0,
            _kHomeContentMaxWidth,
          );
          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
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
      ),
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
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '首页',
              style: TextStyle(
                color: cs.textPrimary,
                fontSize: 26,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.4,
              ),
            ),
            SizedBox(height: tokens.spacing.xs),
            Text(
              '${_greetingPhraseForNow()}，读者',
              style: TextStyle(color: cs.textTertiary, fontSize: 13),
            ),
          ],
        ),
        Row(
          spacing: 8,
          children: [
            GhostButton.icon(
              icon: LucideIcons.refreshCw,
              tooltip: '刷新漫画库列表',
              semanticLabel: '刷新漫画库列表',
              iconSize: 18,
              size: 36,
              borderRadius: 10,
              foregroundColor: cs.iconDefault,
              hoverColor: cs.surfaceContainerHighest,
              overlayColor: cs.primary.withAlpha(32),
              delayTooltipThreeSeconds: false,
              onPressed: () {
                ref.read(libraryPageProvider.notifier).refreshStream();
              },
            ),
            FilledButton.icon(
              onPressed: () => _onTapScanLibrary(context, ref),
              icon: const Icon(LucideIcons.scanSearch, size: 18),
              label: const Text('扫描漫画库'),
              style: FilledButton.styleFrom(
                backgroundColor: cs.primary,
                foregroundColor: cs.onPrimary,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
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
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(tokens.spacing.lg + 12),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(LucideIcons.folderOpen, size: 40, color: cs.primary),
              SizedBox(width: tokens.spacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '尚未导入漫画',
                      style: TextStyle(
                        fontSize: tokens.text.titleMd,
                        fontWeight: FontWeight.w600,
                        color: cs.textPrimary,
                      ),
                    ),
                    SizedBox(height: tokens.spacing.sm),
                    Text(
                      '请先在设置中添加库文件夹并扫描；若已配置，可检查选中路径或重新扫描。',
                      style: TextStyle(
                        fontSize: tokens.text.bodySm,
                        color: cs.textSecondary,
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: tokens.spacing.lg),
          Wrap(
            spacing: tokens.spacing.sm,
            runSpacing: tokens.spacing.sm,
            children: [
              FilledButton.icon(
                onPressed: () => _onTapScanLibrary(context, ref),
                icon: const Icon(LucideIcons.scanSearch, size: 18),
                label: const Text('扫描漫画库'),
                style: FilledButton.styleFrom(
                  backgroundColor: cs.primary,
                  foregroundColor: cs.onPrimary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              OutlinedButton.icon(
                onPressed: () => context.go('/paths'),
                icon: const Icon(LucideIcons.folderTree, size: 18),
                label: const Text('选中路径'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: cs.textPrimary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              OutlinedButton.icon(
                onPressed: () => context.go('/settings'),
                icon: const Icon(LucideIcons.settings, size: 18),
                label: const Text('设置'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: cs.textPrimary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
        ],
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
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final bool stack =
            constraints.maxWidth < _kHomeStatsStackBreakpointWidth;
        if (stack) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: context.tokens.spacing.md,
            children: [
              _StatSummaryCard(
                label: '漫画库',
                valueText: '$comicCount',
                caption: '共 $comicCount 本',
                icon: LucideIcons.bookImage,
              ),
              _StatSummaryCard(
                label: '阅读记录',
                valueText: '$historyCount',
                caption: historyCount == 0 ? '暂无历史' : '$historyCount 条',
                icon: LucideIcons.history,
              ),
              Row(
                spacing: context.tokens.spacing.md,
                children: [
                  Expanded(
                    child: _StatSummaryCard(
                      label: '系列',
                      valueText: '$seriesCount',
                      caption: '$seriesCount 个',
                      icon: LucideIcons.library,
                    ),
                  ),
                  Expanded(
                    child: _StatSummaryCard(
                      label: '标签',
                      valueText: '$tagCount',
                      caption: '$tagCount 个',
                      icon: LucideIcons.tags,
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
              ),
            ),
            Expanded(
              child: _StatSummaryCard(
                label: '系列',
                valueText: '$seriesCount',
                caption: '$seriesCount 个系列',
                icon: LucideIcons.library,
              ),
            ),
            Expanded(
              child: _StatSummaryCard(
                label: '标签',
                valueText: '$tagCount',
                caption: '$tagCount 个标签',
                icon: LucideIcons.tags,
              ),
            ),
            Expanded(
              child: _StatSummaryCard(
                label: '阅读记录',
                valueText: '$historyCount',
                caption: historyCount == 0 ? '暂无历史' : '$historyCount 条',
                icon: LucideIcons.history,
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
    final HistoryFeedViewData historyFeedView = ref.watch(
      historyFeedViewProvider,
    );
    final bool loading = historyFeedView.isLoading;
    final bool hasError = historyFeedView.hasError;
    final List<HistoryGridItemDto> visible =
        historyFeedView.continueReadingItems;
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
              icon: LucideIcons.tags,
              label: '标签管理',
              onTap: () => context.go('/tags'),
              colorScheme: cs,
              tokens: tokens,
            ),
            _ShortcutTile(
              icon: LucideIcons.penLine,
              label: '作者管理',
              onTap: () => context.go('/authors'),
              colorScheme: cs,
              tokens: tokens,
            ),
            _ShortcutTile(
              icon: LucideIcons.layers2,
              label: '系列管理',
              onTap: () => context.go('/series'),
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

class _StatSummaryCard extends StatelessWidget {
  const _StatSummaryCard({
    required this.label,
    required this.valueText,
    required this.caption,
    required this.icon,
  });

  final String label;
  final String valueText;
  final String caption;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final AppThemeTokens tokens = context.tokens;
    final ColorScheme cs = theme.colorScheme;
    return Container(
      padding: EdgeInsets.all(tokens.spacing.lg + 8),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.borderSubtle),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: tokens.text.labelXs,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.2,
                    color: cs.textTertiary,
                  ),
                ),
                SizedBox(height: tokens.spacing.sm),
                Text(
                  valueText,
                  style: TextStyle(
                    fontSize: tokens.text.titleLg + 4,
                    fontWeight: FontWeight.w600,
                    color: cs.textPrimary,
                  ),
                ),
                SizedBox(height: tokens.spacing.sm - 2),
                Text(
                  caption,
                  style: TextStyle(
                    fontSize: tokens.text.bodySm,
                    color: cs.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.all(tokens.spacing.sm),
            child: Icon(icon, size: 32, color: cs.primary),
          ),
        ],
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
    final Duration duration = const Duration(milliseconds: 180);
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
