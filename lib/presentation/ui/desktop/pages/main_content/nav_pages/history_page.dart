import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/config/theme.dart';
import 'package:hentai_library/presentation/ui/desktop/widgets/custom_toast.dart';
import 'package:hentai_library/presentation/providers/providers.dart';
import 'package:hentai_library/presentation/ui/shared/routing/app_router.dart';
import 'package:hentai_library/presentation/ui/shared/routing/reader_route_args.dart';
import 'package:hentai_library/presentation/dto/history_grid_item_dto.dart';
import 'package:hentai_library/presentation/ui/desktop/widgets/button/ghost_button.dart';
import 'package:hentai_library/presentation/ui/desktop/widgets/element/reading_history_card.dart';
import 'package:hentai_library/presentation/ui/desktop/widgets/dialog/clear_reading_history_confirm_dialog.dart';
import 'package:hentai_library/presentation/ui/desktop/widgets/input/custom_text_field.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// 根节点不持有搜索 state：搜索写入 [historySearchQueryProvider]，仅列表区 watch，
/// 避免输入时重建标题栏。列表内对 [historyFeedViewProvider] 使用 `select` 缩小刷新面。
class HistoryPage extends ConsumerWidget {
  const HistoryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 16,
        children: const [
          _Header(),
          _HistoryList(),
        ],
      ),
    );
  }
}

class _HistoryStyles {
  const _HistoryStyles._();
  static const double titleFontSize = 26;
  static const double subtitleFontSize = 13;
}

class _Header extends ConsumerWidget {
  const _Header();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final int totalCount = ref.watch(
      historyFeedViewProvider.select(
        (HistoryFeedViewData value) => value.totalCount,
      ),
    );

    return Container(
      padding: const EdgeInsets.all(2),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 6,
            children: [
              Text(
                "阅读历史",
                style: TextStyle(
                  color: theme.colorScheme.textPrimary,
                  fontSize: _HistoryStyles.titleFontSize,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.4,
                ),
              ),
              Text(
                "$totalCount 条记录 • 最长保留 30 天",
                style: TextStyle(
                  fontSize: _HistoryStyles.subtitleFontSize,
                  fontWeight: FontWeight.w400,
                  color: theme.colorScheme.textTertiary,
                ),
              ),
            ],
          ),
          const Spacer(),
          SizedBox(
            width: MediaQuery.of(context).size.width * 0.2,
            child: CustomTextField(
              hintText: "搜索历史记录...",
              onChanged: (String value) =>
                  ref.read(historySearchQueryProvider.notifier).setQuery(value),
            ),
          ),
          const SizedBox(width: 12),
          _buildClearBtn(context, ref, totalCount > 0),
        ],
      ),
    );
  }

  Widget _buildClearBtn(BuildContext context, WidgetRef ref, bool enabled) {
    final cs = Theme.of(context).colorScheme;
    return GhostButton.iconText(
      icon: LucideIcons.trash2,
      text: '清空',
      tooltip: '清空阅读历史',
      semanticLabel: '清空阅读历史',
      onPressed: !enabled
          ? null
          : () async {
              final bool confirmed =
                  await showDialog<bool>(
                    context: context,
                    builder: (BuildContext context) =>
                        const ClearReadingHistoryConfirmDialog(),
                  ) ??
                  false;
              if (!confirmed) {
                return;
              }
              try {
                await ref.read(readingHistoryRepoProvider).clearAllHistory();
                if (context.mounted) {
                  showSuccessToast(context, '已清空阅读历史');
                }
              } catch (e) {
                if (context.mounted) {
                  showErrorToast(context, e);
                }
              }
            },
      foregroundColor: cs.warning,
      hoverColor: cs.error.withAlpha(24),
      overlayColor: cs.error.withAlpha(20),
    );
  }
}

class _HistoryList extends ConsumerWidget {
  const _HistoryList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final bool isLoading = ref.watch(
      historyFeedViewProvider.select(
        (HistoryFeedViewData d) => d.isLoading,
      ),
    );
    if (isLoading) {
      return const Padding(
        padding: EdgeInsets.only(top: 48),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    final bool hasError = ref.watch(
      historyFeedViewProvider.select(
        (HistoryFeedViewData d) => d.hasError,
      ),
    );
    if (hasError) {
      return Padding(
        padding: const EdgeInsets.only(top: 48),
        child: Center(
          child: Text(
            '加载失败',
            style: TextStyle(
              fontSize: 14,
              color: theme.colorScheme.textSecondary,
            ),
          ),
        ),
      );
    }
    final List<HistoryGridItemDto> merged = ref.watch(
      historyFeedViewProvider.select(
        (HistoryFeedViewData d) => d.mergedItems,
      ),
    );
    final String query = ref.watch(historySearchQueryProvider);

    final String q = query.trim().toLowerCase();
    final List<HistoryGridItemDto> filtered = q.isEmpty
        ? merged
        : merged
            .where((HistoryGridItemDto h) => h.title.toLowerCase().contains(q))
            .toList(growable: false);

    if (filtered.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(top: 48),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            spacing: 8,
            children: [
              Icon(
                LucideIcons.bookOpen,
                size: 48,
                color: theme.colorScheme.textTertiary,
              ),
              Text(
                q.isEmpty ? '暂无阅读历史' : '没有匹配的历史记录',
                style: TextStyle(
                  fontSize: 14,
                  color: theme.colorScheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double width = constraints.maxWidth;
        int crossAxisCount = 2;
        if (width >= 1600) {
          crossAxisCount = 5;
        } else if (width >= 1300) {
          crossAxisCount = 4;
        } else if (width >= 980) {
          crossAxisCount = 3;
        }
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: filtered.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            mainAxisExtent: 138,
          ),
          itemBuilder: (BuildContext context, int index) {
            final HistoryGridItemDto item = filtered[index];
            if (item is ComicHistoryGridItemDto) {
              return ReadingHistoryCard.comic(
                comicId: item.comicId,
                title: item.title,
                lastReadTime: item.lastReadTime,
                pageIndex: item.pageIndex,
                onTap: () => appRouter.pushNamed(
                  ReaderRouteArgs.readerRouteName,
                  queryParameters: ReaderRouteArgs(
                    comicId: item.comicId,
                    readType: ReaderRouteArgs.readTypeComic,
                  ).toQueryParameters(),
                ),
                onDelete: () => _handleDeleteComicHistory(
                  context: context,
                  ref: ref,
                  comicId: item.comicId,
                ),
              );
            }
            final SeriesHistoryGridItemDto seriesItem = item as SeriesHistoryGridItemDto;
            return ReadingHistoryCard.series(
              seriesName: seriesItem.seriesName,
              lastReadComicId: seriesItem.lastReadComicId,
              lastReadTime: seriesItem.lastReadTime,
              pageIndex: seriesItem.pageIndex,
              lastReadComicOrder: seriesItem.lastReadComicOrder,
              onTap: () => appRouter.pushNamed(
                ReaderRouteArgs.readerRouteName,
                queryParameters: ReaderRouteArgs(
                  comicId: seriesItem.lastReadComicId,
                  readType: ReaderRouteArgs.readTypeSeries,
                  seriesName: seriesItem.seriesName,
                ).toQueryParameters(),
              ),
              onDelete: () => _handleDeleteSeriesHistory(
                context: context,
                ref: ref,
                seriesName: seriesItem.seriesName,
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _handleDeleteComicHistory({
    required BuildContext context,
    required WidgetRef ref,
    required String comicId,
  }) async {
    try {
      await ref.read(readingHistoryRepoProvider).deleteByComicId(comicId);
      if (context.mounted) {
        showSuccessToast(context, '已删除记录');
      }
    } catch (e) {
      if (context.mounted) {
        showErrorToast(context, e);
      }
    }
  }

  Future<void> _handleDeleteSeriesHistory({
    required BuildContext context,
    required WidgetRef ref,
    required String seriesName,
  }) async {
    try {
      await ref
          .read(readingHistoryRepoProvider)
          .deleteSeriesReadingBySeriesName(seriesName);
      if (context.mounted) {
        showSuccessToast(context, '已删除记录');
      }
    } catch (e) {
      if (context.mounted) {
        showErrorToast(context, e);
      }
    }
  }
}
