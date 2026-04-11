import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hentai_library/config/theme.dart';
import 'package:hentai_library/core/l10n/app_strings.dart';
import 'package:hentai_library/domain/entity/comic/comic.dart';
import 'package:hentai_library/domain/entity/comic/series.dart';
import 'package:hentai_library/domain/value_objects/library_display_target.dart';
import 'package:hentai_library/presentation/providers/providers.dart';
import 'package:hentai_library/presentation/routes/routes.dart';
import 'package:hentai_library/presentation/widgets/button/filter_popup_button.dart';
import 'package:hentai_library/presentation/widgets/button/ghost_button.dart';
import 'package:hentai_library/presentation/widgets/button/sort_popup_button.dart';
import 'package:hentai_library/presentation/widgets/card_item/comic_card.dart';
import 'package:hentai_library/presentation/widgets/card_item/comic_tile.dart';
import 'package:hentai_library/presentation/widgets/card_item/series_card.dart';
import 'package:hentai_library/presentation/widgets/card_item/series_tile.dart';
import 'package:hentai_library/presentation/widgets/input/custom_text_field.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

const double _kLibraryGridMaxCrossAxisExtent = 200;
const double _kLibraryGridCrossAxisSpacing = 16;
const double _kLibraryGridMainAxisSpacing = 16;

/// Vertical cell size for library comic/series grids, aligned with [ComicCard] and [SeriesCard]:
/// `padding` 2× [AppSpacingTokens.sm], cover [AspectRatio] 2:3 on inner width, `Column.spacing` 12
/// before the info block, title line (`bodyMd` × 1.25) + spacing 6 + meta line (`labelXs` − 1),
/// plus slack for hover shadow and rounding (historically fixed `mainAxisExtent: 356`).
double _libraryGridMainAxisExtentFromTokens(AppThemeTokens tokens) {
  final double pad = tokens.spacing.sm;
  final double innerWidth = _kLibraryGridMaxCrossAxisExtent - 2 * pad;
  final double coverHeight = innerWidth * 3 / 2;
  const double coverToInfoGap = 12;
  final double titleLineHeight = tokens.text.bodyMd * 1.25;
  const double infoColumnSpacing = 6;
  final double metaLineHeight = tokens.text.labelXs - 1;
  return (2 * pad +
          coverHeight +
          coverToInfoGap +
          titleLineHeight +
          infoColumnSpacing +
          metaLineHeight)
          .ceil() +
      16;
}

SliverGridDelegate _libraryGridDelegate(AppThemeTokens tokens) {
  return SliverGridDelegateWithMaxCrossAxisExtent(
    maxCrossAxisExtent: _kLibraryGridMaxCrossAxisExtent,
    mainAxisExtent: _libraryGridMainAxisExtentFromTokens(tokens),
    crossAxisSpacing: _kLibraryGridCrossAxisSpacing,
    mainAxisSpacing: _kLibraryGridMainAxisSpacing,
  );
}

class LibraryPage extends ConsumerStatefulWidget {
  const LibraryPage({super.key});

  @override
  ConsumerState<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends ConsumerState<LibraryPage> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final query = ref.read(libraryPageProvider).effectiveFilter.query ?? '';
      if (_searchController.text != query) {
        _searchController.text = query;
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final comics = ref.watch(
      libraryPageProvider.select((s) => s.comicsAsyncValue),
    );
    final isGridView = ref.watch(
      libraryPageProvider.select((s) => s.isGridView),
    );
    final filterQuery = ref.watch(
      libraryPageProvider.select((s) => s.effectiveFilter.query ?? ''),
    );
    final LibraryDisplayTarget displayTarget = ref.watch(
      libraryPageProvider.select((s) => s.effectiveFilter.displayTarget),
    );

    if (_searchController.text != filterQuery) {
      _searchController.value = _searchController.value.copyWith(
        text: filterQuery,
        selection: TextSelection.collapsed(offset: filterQuery.length),
      );
    }

    final int comicCount = ref.watch(
      libraryPageProvider.select((s) => s.rawList.length),
    );
    final bool isComicTableEmpty = ref.watch(
      libraryPageProvider.select(
        (s) => s.hasReceivedFirstEmit && s.rawList.isEmpty,
      ),
    );

    final AsyncValue<List<Series>> seriesAsync = ref.watch(allSeriesProvider);
    final int seriesCount = seriesAsync.when(
      data: (List<Series> list) =>
          list.where((Series series) => series.items.isNotEmpty).length,
      error: (Object err, StackTrace stack) => 0,
      loading: () => 0,
      skipLoadingOnReload: true,
    );
    final List<Series> seriesToShow = seriesAsync.maybeWhen(
      data: (List<Series> list) => _filterSeriesForLibrary(list, filterQuery),
      orElse: () => <Series>[],
    );
    final bool showSeriesSection = displayTarget != LibraryDisplayTarget.comics;
    final bool showComicsSection = displayTarget != LibraryDisplayTarget.series;
    final bool hasSeriesSection = showSeriesSection && seriesToShow.isNotEmpty;

    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: <Widget>[
        SliverToBoxAdapter(
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 48, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 标题行
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      AppStrings.libraryTitle,
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.textPrimary,
                        letterSpacing: -0.4,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: theme.colorScheme.borderSubtle,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            LucideIcons.library,
                            size: 14,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            AppStrings.comicCount(comicCount),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: theme.colorScheme.borderSubtle,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            LucideIcons.bookMarked,
                            size: 14,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '$seriesCount 个系列',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '浏览、搜索与筛选本地漫画',
                  style: TextStyle(
                    fontSize: 13,
                    color: theme.colorScheme.textTertiary,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    ConstrainedBox(
                      constraints: const BoxConstraints(
                        minWidth: 240,
                        maxWidth: 420,
                      ),
                      child: CustomTextField(
                        controller: _searchController,
                        hintText: '搜索…',
                        onChanged: (val) => ref
                            .read(libraryPageProvider.notifier)
                            .updateFilterQuery(val),
                      ),
                    ),
                    const Spacer(),
                    // 右侧工具栏（刷新 / 筛选 / 排序 / 视图切换）
                    _buildToolbar(context, theme, isGridView),
                  ],
                ),
              ],
            ),
          ),
        ),
        if (showSeriesSection)
          ..._buildSeriesSectionSlivers(
            context: context,
            isGridView: isGridView,
            series: seriesToShow,
          ),
        if (showSeriesSection && !showComicsSection && seriesToShow.isEmpty)
          _NoMatchingSeriesSliver(query: filterQuery),
        if (showComicsSection)
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 2),
            sliver: isGridView
                ? _buildGridView(
                    comics,
                    hasSeriesSection: hasSeriesSection,
                    isComicTableEmpty: isComicTableEmpty,
                  )
                : _buildListView(
                    comics,
                    hasSeriesSection: hasSeriesSection,
                    isComicTableEmpty: isComicTableEmpty,
                  ),
          ),
      ],
    );
  }

  List<Series> _filterSeriesForLibrary(List<Series> all, String query) {
    final String q = query.trim().toLowerCase();
    final List<Series> out = <Series>[];
    for (final Series s in all) {
      if (s.items.isEmpty) {
        continue;
      }
      if (q.isEmpty || s.name.toLowerCase().contains(q)) {
        out.add(s);
      }
    }
    return out;
  }

  List<Widget> _buildSeriesSectionSlivers({
    required BuildContext context,
    required bool isGridView,
    required List<Series> series,
  }) {
    if (series.isEmpty) {
      return <Widget>[];
    }

    final ThemeData theme = Theme.of(context);

    return <Widget>[
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 4),
          child: Text(
            '系列',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.textSecondary,
            ),
          ),
        ),
      ),
      SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 48),
        sliver: isGridView
            ? SliverGrid.builder(
                gridDelegate: _libraryGridDelegate(context.tokens),
                itemCount: series.length,
                itemBuilder: (BuildContext context, int index) {
                  final Series s = series[index];
                  return Center(
                    child: SeriesCard(
                      key: Key('library-series-${s.name}'),
                      series: s,
                      size: const Size(double.infinity, double.infinity),
                      onTap: () {
                        appRouter.pushNamed(
                          '系列详情',
                          pathParameters: <String, String>{'name': s.name},
                        );
                      },
                    ),
                  );
                },
              )
            : SliverList.separated(
                itemCount: series.length,
                separatorBuilder: (BuildContext context, int index) =>
                    const SizedBox(height: 8),
                itemBuilder: (BuildContext context, int index) {
                  final Series s = series[index];
                  return SeriesTile(
                    key: Key('library-series-${s.name}'),
                    series: s,
                    onTap: () {
                      appRouter.pushNamed(
                        '系列详情',
                        pathParameters: <String, String>{'name': s.name},
                      );
                    },
                    onSecondaryTapDown: (_) {},
                  );
                },
              ),
      ),
      const SliverToBoxAdapter(child: SizedBox(height: 16)),
    ];
  }

  Widget _buildToolbar(BuildContext context, ThemeData theme, bool isGridView) {
    final ColorScheme cs = theme.colorScheme;
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.borderSubtle),
      ),
      padding: const EdgeInsets.all(3),
      child: Row(
        children: [
          // 功能按钮组 (Refresh, Filter, Sort)
          GhostButton.icon(
            icon: LucideIcons.rotateCw,
            tooltip: '刷新',
            semanticLabel: '刷新',
            iconSize: 16,
            size: 28,
            borderRadius: 6,
            foregroundColor: cs.iconDefault,
            hoverColor: theme.hoverColor,
            overlayColor: theme.hoverColor,
            delayTooltipThreeSeconds: true,
            onPressed: () {
              ref.read(libraryPageProvider.notifier).refreshStream();
            },
          ),
          const SizedBox(width: 8),
          FilterPopupButton(),
          const SizedBox(width: 8),
          SortPopupButton(),
          // 垂直分割线
          const SizedBox(width: 12),
          DecoratedBox(
            decoration: BoxDecoration(
              color: cs.borderSubtle,
              borderRadius: BorderRadius.circular(999),
            ),
            child: const SizedBox(width: 1, height: 22),
          ),
          const SizedBox(width: 12),

          // 视图切换 (Grid/List)
          Row(
            children: [
              _ViewToggleButton(
                icon: LucideIcons.layoutGrid,
                isActive: isGridView,
                onTap: () =>
                    ref.read(libraryPageProvider.notifier).setGridView(true),
                activeColor: theme.colorScheme.primary,
              ),
              const SizedBox(width: 4),
              _ViewToggleButton(
                icon: LucideIcons.list,
                isActive: !isGridView,
                onTap: () =>
                    ref.read(libraryPageProvider.notifier).setGridView(false),
                activeColor: theme.colorScheme.primary,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 构建网格视图
  Widget _buildGridView(
    AsyncValue<List<Comic>> comics, {
    required bool hasSeriesSection,
    required bool isComicTableEmpty,
  }) {
    return comics.when(
      data: (List<Comic> comics) {
        final String q = _searchController.text.trim();
        if (comics.isEmpty) {
          if (hasSeriesSection) {
            return _NoMatchingComicsSliver(
              query: q,
              showManagePathsEntry: isComicTableEmpty,
            );
          }
          return _EmptyLibrarySliver(
            query: q,
            showManagePathsEntry: isComicTableEmpty,
          );
        }
        return SliverGrid.builder(
          gridDelegate: _libraryGridDelegate(context.tokens),
          itemCount: comics.length,
          itemBuilder: (BuildContext context, int index) {
            final manga = comics[index];
            return Center(
              child: ComicCard(
                key: Key(manga.comicId),
                comic: manga,
                size: const Size(double.infinity, double.infinity),
                onTap: () {
                  appRouter.pushNamed(
                    '漫画详情',
                    pathParameters: {'id': manga.comicId},
                  );
                },
                onPlay: () {},
              ),
            );
          },
        );
      },
      error: (err, stack) => SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text('Error: $err'),
        ),
      ),
      loading: () => SliverToBoxAdapter(
        child: const Center(child: CircularProgressIndicator()),
      ),
      skipLoadingOnReload: true,
    );
  }

  // 构建列表视图
  Widget _buildListView(
    AsyncValue<List<Comic>> comics, {
    required bool hasSeriesSection,
    required bool isComicTableEmpty,
  }) {
    return comics.when(
      data: (List<Comic> comics) {
        final String q = _searchController.text.trim();
        if (comics.isEmpty) {
          if (hasSeriesSection) {
            return _NoMatchingComicsSliver(
              query: q,
              showManagePathsEntry: isComicTableEmpty,
            );
          }
          return _EmptyLibrarySliver(
            query: q,
            showManagePathsEntry: isComicTableEmpty,
          );
        }
        return SliverList.separated(
          itemCount: comics.length,
          separatorBuilder: (ctx, i) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final manga = comics[index];
            return ComicTile(
              key: Key(manga.comicId),
              comic: manga,
              onTap: () {
                appRouter.pushNamed(
                  '漫画详情',
                  pathParameters: {'id': manga.comicId},
                );
              },
            );
          },
        );
      },
      error: (err, stack) => SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text('Error: $err'),
        ),
      ),
      loading: () => SliverFillRemaining(
        hasScrollBody: false,
        child: const Center(child: CircularProgressIndicator()),
      ),
      skipLoadingOnReload: true,
    );
  }
}

class _NoMatchingComicsSliver extends StatelessWidget {
  const _NoMatchingComicsSliver({
    this.query = '',
    this.showManagePathsEntry = false,
  });

  final String query;
  final bool showManagePathsEntry;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final String q = query.trim();
    final bool hasQuery = q.isNotEmpty;
    final String message = hasQuery ? '无匹配漫画（可尝试调整搜索或筛选）' : '暂无漫画';
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.only(top: 24, bottom: 48),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            spacing: 16,
            children: [
              Text(
                message,
                style: TextStyle(
                  fontSize: 13,
                  color: theme.colorScheme.textTertiary,
                ),
                textAlign: TextAlign.center,
              ),
              if (showManagePathsEntry)
                OutlinedButton.icon(
                  onPressed: () => context.go('/paths'),
                  icon: Icon(
                    LucideIcons.folderTree,
                    size: 16,
                    color: theme.colorScheme.primary,
                  ),
                  label: const Text('管理扫描路径'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: theme.colorScheme.primary,
                    side: BorderSide(color: theme.colorScheme.borderSubtle),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NoMatchingSeriesSliver extends StatelessWidget {
  const _NoMatchingSeriesSliver({this.query = ''});

  final String query;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final String q = query.trim();
    final bool hasQuery = q.isNotEmpty;
    final String message = hasQuery ? '无匹配系列' : '暂无系列';
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.only(top: 24, bottom: 48),
        child: Center(
          child: Text(
            message,
            style: TextStyle(
              fontSize: 13,
              color: theme.colorScheme.textTertiary,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}

class _EmptyLibrarySliver extends StatelessWidget {
  const _EmptyLibrarySliver({
    this.query = '',
    this.showManagePathsEntry = false,
  });

  final String query;
  final bool showManagePathsEntry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final q = query.trim();
    final isSearching = q.isNotEmpty;
    final title = isSearching
        ? AppStrings.libraryNoMatchTitle
        : AppStrings.libraryEmptyTitle;
    final hint = isSearching
        ? AppStrings.libraryNoMatchHint(q)
        : AppStrings.libraryEmptyHint;
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.only(top: 80),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            spacing: 12,
            children: [
              Icon(
                LucideIcons.library,
                size: 56,
                color: theme.colorScheme.textTertiary,
              ),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.textPrimary,
                ),
              ),
              Text(
                hint,
                style: TextStyle(
                  fontSize: 13,
                  color: theme.colorScheme.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              if (showManagePathsEntry)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: OutlinedButton.icon(
                    onPressed: () => context.go('/paths'),
                    icon: Icon(
                      LucideIcons.folderTree,
                      size: 16,
                      color: theme.colorScheme.primary,
                    ),
                    label: const Text('管理扫描路径'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: theme.colorScheme.primary,
                      side: BorderSide(color: theme.colorScheme.borderSubtle),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ViewToggleButton extends StatelessWidget {
  final IconData icon;
  final bool isActive;
  final VoidCallback onTap;
  final Color activeColor;

  const _ViewToggleButton({
    required this.icon,
    required this.isActive,
    required this.onTap,
    required this.activeColor,
  });

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme cs = theme.colorScheme;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        hoverColor: theme.hoverColor,
        splashFactory: NoSplash.splashFactory,
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: isActive ? cs.subtleTagBackground : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isActive ? cs.borderSubtle : Colors.transparent,
            ),
          ),
          child: Icon(
            icon,
            size: 16,
            color: isActive ? activeColor : cs.iconSecondary,
          ),
        ),
      ),
    );
  }
}

