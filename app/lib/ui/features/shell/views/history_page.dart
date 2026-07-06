import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/ui/core/theme/theme.dart';
import 'package:hentai_library/ui/core/widgets/feedback/custom_toast.dart';
import 'package:hentai_library/ui/providers.dart';
import 'package:hentai_library/ui/features/shell/views/routing/app_router.dart';
import 'package:hentai_library/ui/features/shell/views/routing/reader_route_args.dart';
import 'package:hentai_library/ui/core/dto/history_grid_item_dto.dart';
import 'package:hentai_library/ui/core/widgets/actions/ghost_button.dart';
import 'package:hentai_library/ui/core/widgets/element/card/reading_history_card.dart';
import 'package:hentai_library/ui/core/widgets/overlays/dialog/confirm/clear_reading_history_confirm_dialog.dart';
import 'package:hentai_library/ui/core/widgets/form/custom_text_field.dart';
import 'package:hentai_library/ui/features/shell/view_models/history_paged_feed_state.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

const double _kHistoryLoadMoreThreshold = 400;

class HistoryPage extends ConsumerWidget {
  const HistoryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppThemeTokens tokens = context.tokens;
    return NotificationListener<ScrollNotification>(
      onNotification: (ScrollNotification notification) {
        if (notification is! ScrollUpdateNotification) {
          return false;
        }
        final ScrollMetrics metrics = notification.metrics;
        if (metrics.maxScrollExtent <= 0) {
          return false;
        }
        final bool nearBottom =
            metrics.pixels >= metrics.maxScrollExtent - _kHistoryLoadMoreThreshold;
        if (!nearBottom) {
          return false;
        }
        ref.read(historyPagedFeedControllerProvider.notifier).loadMore();
        return false;
      },
      child: CustomScrollView(
        cacheExtent: 1200,
        slivers: <Widget>[
          SliverPadding(
            padding: tokens.layout.contentAreaPadding,
            sliver: const SliverToBoxAdapter(child: _Header()),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 16)),
          SliverPadding(
            padding: EdgeInsets.symmetric(
              horizontal: tokens.layout.contentHorizontalPadding,
            ),
            sliver: const _HistoryListSliver(),
          ),
        ],
      ),
    );
  }
}

class _Header extends ConsumerWidget {
  const _Header();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final AppThemeTokens tokens = context.tokens;
    final int totalCount = ref.watch(
      historyPagedFeedControllerProvider.select(
        (AsyncValue<HistoryPagedFeedState> value) =>
            value.asData?.value.totalCount ?? 0,
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
                  color: theme.colorScheme.hentai.textPrimary,
                  fontSize: tokens.text.titleLg + 4,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.4,
                ),
              ),
              Text(
                "$totalCount 条记录 • 最长保留 30 天",
                style: TextStyle(
                  fontSize: tokens.text.bodySm,
                  fontWeight: FontWeight.w400,
                  color: theme.colorScheme.hentai.textTertiary,
                ),
              ),
            ],
          ),
          const Spacer(),
          SizedBox(
            width: MediaQuery.of(context).size.width * 0.2,
            child: CustomTextField(
              hintText: "搜索历史记录...",
              onChanged: (String value) => ref
                  .read(historyPagedFeedControllerProvider.notifier)
                  .setKeyword(value),
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
                ref
                    .read(historyPagedFeedControllerProvider.notifier)
                    .clearAllLocal();
                if (context.mounted) {
                  showSuccessToast(context, '已清空阅读历史');
                }
              } catch (e) {
                if (context.mounted) {
                  showErrorToast(context, e);
                }
              }
            },
      foregroundColor: cs.hentai.warning,
      hoverColor: cs.error.withAlpha(24),
      overlayColor: cs.error.withAlpha(20),
    );
  }
}

class _HistoryListSliver extends ConsumerWidget {
  const _HistoryListSliver();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final AsyncValue<HistoryPagedFeedState> feedAsync = ref.watch(
      historyPagedFeedControllerProvider,
    );
    return feedAsync.when(
      loading: () => const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.only(top: 48),
          child: Center(child: CircularProgressIndicator()),
        ),
      ),
      error: (Object _, StackTrace _) => SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.only(top: 48),
          child: Center(
            child: Text(
              '加载失败',
              style: TextStyle(
                fontSize: 14,
                color: theme.colorScheme.hentai.textSecondary,
              ),
            ),
          ),
        ),
      ),
      data: (HistoryPagedFeedState feed) {
        if (feed.items.isEmpty) {
          return SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(top: 48),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  spacing: 8,
                  children: [
                    Icon(
                      LucideIcons.bookOpen,
                      size: 48,
                      color: theme.colorScheme.hentai.textTertiary,
                    ),
                    Text(
                      feed.keyword.isEmpty ? '暂无阅读历史' : '没有匹配的历史记录',
                      style: TextStyle(
                        fontSize: 14,
                        color: theme.colorScheme.hentai.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        return SliverMainAxisGroup(
          slivers: <Widget>[
            SliverLayoutBuilder(
              builder: (BuildContext context, constraints) {
                final double width = constraints.crossAxisExtent;
                final int crossAxisCount = _resolveCrossAxisCount(width);
                return SliverGrid.builder(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    mainAxisExtent: 138,
                  ),
                  itemCount: feed.items.length,
                  itemBuilder: (BuildContext context, int index) {
                    final HistoryGridItemDto item = feed.items[index];
                    return ReadingHistoryCard(
                      comicId: item.comicId,
                      title: item.title,
                      lastReadTime: item.lastReadTime,
                      pageIndex: item.pageIndex,
                      onTap: () => appRouter.pushNamed(
                        ReaderRouteArgs.readerRouteName,
                        queryParameters: ReaderRouteArgs(
                          comicId: item.comicId,
                        ).toQueryParameters(),
                      ),
                      onDelete: () => _handleDeleteComicHistory(
                        context: context,
                        ref: ref,
                        comicId: item.comicId,
                      ),
                    );
                  },
                );
              },
            ),
            if (feed.isLoadingMore)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  int _resolveCrossAxisCount(double width) {
    if (width >= 1600) {
      return 5;
    }
    if (width >= 1300) {
      return 4;
    }
    if (width >= 980) {
      return 3;
    }
    return 2;
  }

  Future<void> _handleDeleteComicHistory({
    required BuildContext context,
    required WidgetRef ref,
    required String comicId,
  }) async {
    try {
      await ref.read(readingHistoryRepoProvider).deleteByComicId(comicId);
      ref.read(historyPagedFeedControllerProvider.notifier).removeItem(comicId);
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
