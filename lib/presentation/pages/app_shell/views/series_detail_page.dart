import 'dart:io';
import 'dart:math' as math;

import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hentai_library/config/theme.dart';
import 'package:hentai_library/core/util/snackbar_util.dart';
import 'package:hentai_library/domain/entity/comic/series.dart';
import 'package:hentai_library/domain/entity/comic/series_item.dart';
import 'package:hentai_library/domain/entity/series_reading_history.dart';
import 'package:hentai_library/presentation/providers/providers.dart';
import 'package:hentai_library/presentation/routes/routes.dart';
import 'package:hentai_library/presentation/widgets/button/ghost_button.dart';
import 'package:hentai_library/presentation/widgets/dialog/add_comics_to_series_dialog.dart';
import 'package:hentai_library/presentation/widgets/dialog/rename_series_dialog.dart';
import 'package:hentai_library/presentation/widgets/dialog/reorder_series_items_dialog.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class SeriesDetailPage extends ConsumerWidget {
  const SeriesDetailPage({super.key, required this.seriesName});

  final String seriesName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<Series>> seriesAsync = ref.watch(allSeriesProvider);
    return seriesAsync.when(
      data: (List<Series> list) {
        Series? found;
        for (final Series s in list) {
          if (s.name == seriesName) {
            found = s;
            break;
          }
        }
        if (found == null) {
          return _SeriesNotFoundBody(seriesName: seriesName);
        }
        return _SeriesDetailBody(series: found);
      },
      loading: () => const _SeriesDetailLoadingBody(),
      error: (Object e, StackTrace _) => _SeriesDetailErrorBody(error: e),
    );
  }
}

class _SeriesDetailLoadingBody extends StatelessWidget {
  const _SeriesDetailLoadingBody();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 48),
      child: Center(child: CircularProgressIndicator()),
    );
  }
}

class _SeriesDetailErrorBody extends StatelessWidget {
  const _SeriesDetailErrorBody({required this.error});

  final Object error;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text('加载失败：$error', style: TextStyle(color: cs.error, fontSize: 14)),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () => context.go('/local'),
            child: const Text('返回本地漫画'),
          ),
        ],
      ),
    );
  }
}

class _SeriesNotFoundBody extends StatelessWidget {
  const _SeriesNotFoundBody({required this.seriesName});

  final String seriesName;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            '未找到系列「$seriesName」',
            style: TextStyle(fontSize: 14, color: cs.textTertiary),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () => context.go('/local'),
            child: const Text('返回本地漫画'),
          ),
        ],
      ),
    );
  }
}

class _SeriesDetailBody extends ConsumerWidget {
  const _SeriesDetailBody({required this.series});

  final Series series;

  static const double _narrowBreakpoint = 720;
  static const double _kSeriesDetailMaxWidth = 1200;

  /// 与 [ComicDetailPage] 左栏 `_kLeftColumnMaxWidth`、封面 `AspectRatio(2/3)` 一致。
  static const double _kSeriesCoverMaxWidth = 300;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppThemeTokens tokens = context.tokens;
    final ColorScheme cs = Theme.of(context).colorScheme;
    final List<SeriesItem> sortedItems = List<SeriesItem>.from(series.items)
      ..sort((SeriesItem a, SeriesItem b) => a.order.compareTo(b.order));
    final ButtonStyle primarySeriesToolbarStyle = FilledButton.styleFrom(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    );
    final int count = series.items.length;
    final Widget titleBlock = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          series.name,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.4,
            color: cs.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '包含 $count 本',
          style: TextStyle(color: cs.textTertiary, fontSize: 12),
        ),
      ],
    );
    final Widget actions = Wrap(
      spacing: 8,
      runSpacing: 8,
      children: <Widget>[
        FilledButton.icon(
          onPressed: () async {
            if (sortedItems.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('系列内暂无漫画'),
                  behavior: SnackBarBehavior.floating,
                  margin: snackBarMargin(context),
                ),
              );
              return;
            }
            final SeriesReadingHistory? seriesProgress = await ref
                .read(readingHistoryRepoProvider)
                .getSeriesReadingBySeriesName(series.name);
            String comicIdToOpen = sortedItems.first.comicId;
            if (seriesProgress != null) {
              final String lastId = seriesProgress.lastReadComicId;
              final bool lastStillInSeries = sortedItems.any(
                (SeriesItem e) => e.comicId == lastId,
              );
              if (lastStillInSeries) {
                comicIdToOpen = lastId;
              }
            }
            appRouter.pushNamed(
              '阅读页面',
              pathParameters: <String, String>{'id': comicIdToOpen},
              queryParameters: <String, String>{'series': series.name},
            );
          },
          icon: const Icon(LucideIcons.bookOpen, size: 16),
          label: const Text('阅读系列'),
          style: primarySeriesToolbarStyle,
        ),
        GhostButton.icon(
          tooltip: '添加漫画',
          semanticLabel: '添加漫画',
          icon: LucideIcons.plus,
          onPressed: () async {
            await showDialog<void>(
              context: context,
              barrierColor: Colors.transparent,
              builder: (BuildContext context) => AddComicsToSeriesDialog(
                key: ValueKey<String>(series.name),
                series: series,
              ),
            );
          },
        ),
        GhostButton.icon(
          tooltip: '调整顺序',
          semanticLabel: '调整顺序',
          icon: LucideIcons.arrowUpDown,
          onPressed: () {
            if (series.items.length < 2) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('至少需要 2 本漫画才能调整顺序'),
                  behavior: SnackBarBehavior.floating,
                  margin: snackBarMargin(context),
                ),
              );
              return;
            }
            showDialog<void>(
              context: context,
              barrierColor: Colors.transparent,
              builder: (BuildContext context) =>
                  ReorderSeriesItemsDialog(series: series),
            );
          },
        ),
        GhostButton.icon(
          tooltip: '重命名',
          semanticLabel: '重命名',
          icon: LucideIcons.squarePen,
          onPressed: () async {
            final String? newName = await showDialog<String>(
              context: context,
              barrierColor: Colors.transparent,
              builder: (BuildContext context) =>
                  RenameSeriesDialog(series: series),
            );
            if (newName != null && context.mounted) {
              context.goNamed(
                '系列详情',
                pathParameters: <String, String>{'name': newName},
              );
            }
          },
        ),
      ],
    );
    final Widget listSection = Expanded(
      child: _SeriesComicListSection(
        sortedItems: sortedItems,
        seriesName: series.name,
      ),
    );
    final Widget rightColumn = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 16,
      children: <Widget>[titleBlock, actions, listSection],
    );
    return ColoredBox(
      color: cs.winBackground,
      child: Align(
        alignment: Alignment.topCenter,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: tokens.spacing.lg + 8,
            vertical: tokens.spacing.lg + 8,
          ),
          child: _SeriesDetailCard(
            maxWidth: _kSeriesDetailMaxWidth,
            child: Padding(
              padding: EdgeInsets.all(tokens.spacing.xl),
              child: LayoutBuilder(
                builder: (BuildContext context, BoxConstraints constraints) {
                  final bool narrow = constraints.maxWidth < _narrowBreakpoint;
                  final Widget narrowCover = Align(
                    alignment: Alignment.center,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxWidth: _kSeriesCoverMaxWidth,
                      ),
                      child: AspectRatio(
                        aspectRatio: 2 / 3,
                        child: _SeriesCoverBlock(series: series),
                      ),
                    ),
                  );
                  if (narrow) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        narrowCover,
                        const SizedBox(height: 16),
                        Expanded(child: rightColumn),
                      ],
                    );
                  }
                  final double availH = constraints.maxHeight.isFinite
                      ? constraints.maxHeight
                      : MediaQuery.sizeOf(context).height;
                  final double wideMaxMain = math.min(availH * 0.68, 640);
                  return SizedBox(
                    height: wideMaxMain,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        ConstrainedBox(
                          constraints: const BoxConstraints(
                            maxWidth: _kSeriesCoverMaxWidth,
                          ),
                          child: AspectRatio(
                            aspectRatio: 2 / 3,
                            child: _SeriesCoverBlock(series: series),
                          ),
                        ),
                        SizedBox(width: tokens.spacing.lg + 16),
                        Expanded(child: rightColumn),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 与 [ComicDetailPage] 的 `_ComicDetailCard` 相同的卡片阴影与表面层次。
class _SeriesDetailCard extends StatelessWidget {
  const _SeriesDetailCard({required this.maxWidth, required this.child});

  final double maxWidth;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final AppThemeTokens tokens = context.tokens;
    final BorderRadius radius = BorderRadius.circular(tokens.radius.lg);
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: radius,
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: cs.cardShadow,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: radius,
          child: ColoredBox(
            color: cs.surface,
            child: DecoratedBox(
              decoration: BoxDecoration(
                border: Border.all(color: cs.borderSubtle),
              ),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

class _SeriesCoverBlock extends ConsumerWidget {
  const _SeriesCoverBlock({required this.series});

  final Series series;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppThemeTokens tokens = context.tokens;
    final ColorScheme cs = Theme.of(context).colorScheme;
    final SeriesItem? coverItem = series.coverItem;
    final String? coverComicId = coverItem?.comicId;
    final String? coverPath = coverComicId != null
        ? ref
              .watch(comicCoverPathProvider(comicId: coverComicId))
              .maybeWhen(data: (String? v) => v, orElse: () => null)
        : null;
    final Widget content = Container(
      width: double.infinity,
      height: double.infinity,
      color: cs.imagePlaceholder,
      child: coverPath != null
          ? ExtendedImage.file(
              File(coverPath),
              fit: BoxFit.cover,
              cacheWidth: 720,
            )
          : Icon(Icons.broken_image, color: cs.iconSecondary, size: 40),
    );
    return ClipRRect(
      borderRadius: BorderRadius.circular(tokens.radius.lg),
      child: SizedBox.expand(child: content),
    );
  }
}

class _SeriesComicListSection extends StatelessWidget {
  const _SeriesComicListSection({
    required this.sortedItems,
    required this.seriesName,
  });

  final List<SeriesItem> sortedItems;
  final String seriesName;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.borderSubtle),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest,
                border: Border(bottom: BorderSide(color: cs.borderSubtle)),
              ),
              child: Row(
                children: <Widget>[
                  Icon(
                    LucideIcons.bookOpen,
                    size: 14,
                    color: cs.onSurfaceVariant,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '系列内漫画',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: cs.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: sortedItems.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 32,
                        ),
                        child: Text(
                          '暂无漫画，点击「添加漫画」加入',
                          style: TextStyle(
                            fontSize: 14,
                            color: cs.textTertiary,
                          ),
                        ),
                      ),
                    )
                  : ListView.separated(
                      padding: EdgeInsets.zero,
                      itemCount: sortedItems.length,
                      separatorBuilder: (BuildContext context, int _) =>
                          Divider(height: 1, color: cs.borderSubtle),
                      itemBuilder: (BuildContext context, int index) {
                        final SeriesItem item = sortedItems[index];
                        return _SeriesComicRow(
                          item: item,
                          sequenceNumber: index + 1,
                          seriesName: seriesName,
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SeriesComicRow extends ConsumerWidget {
  const _SeriesComicRow({
    required this.item,
    required this.sequenceNumber,
    required this.seriesName,
  });

  final SeriesItem item;
  final int sequenceNumber;
  final String seriesName;

  static String _titleForComic(WidgetRef ref, String comicId) {
    final String? title = ref
        .read(libraryPageProvider.notifier)
        .comicById(comicId)
        ?.title;
    if (title != null && title.isNotEmpty) {
      return title;
    }
    return comicId.length > 12 ? '${comicId.substring(0, 12)}…' : comicId;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final AppThemeTokens tokens = context.tokens;
    final String? coverPath = ref
        .watch(comicCoverPathProvider(comicId: item.comicId))
        .maybeWhen(data: (String? v) => v, orElse: () => null);
    final String title = _titleForComic(ref, item.comicId);
    return Material(
      color: cs.surface,
      child: InkWell(
        onTap: () {
          appRouter.pushNamed(
            '阅读页面',
            pathParameters: <String, String>{'id': item.comicId},
            queryParameters: <String, String>{'series': seriesName},
          );
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          child: Row(
            children: <Widget>[
              SizedBox(
                width: 26,
                child: Text(
                  '$sequenceNumber',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: cs.textSecondary,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(tokens.radius.sm),
                child: Container(
                  width: 36,
                  height: 50,
                  color: cs.imagePlaceholder,
                  child: coverPath != null
                      ? ExtendedImage.file(
                          File(coverPath),
                          fit: BoxFit.cover,
                          cacheWidth: 160,
                        )
                      : Icon(
                          Icons.broken_image,
                          color: cs.iconSecondary,
                          size: 18,
                        ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: cs.textPrimary,
                    height: 1.25,
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
