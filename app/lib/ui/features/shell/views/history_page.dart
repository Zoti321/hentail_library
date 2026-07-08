import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/ui/core/layout/content_search_width.dart';
import 'package:hentai_library/ui/core/theme/theme.dart';
import 'package:hentai_library/ui/core/widgets/feedback/custom_toast.dart';
import 'package:hentai_library/ui/providers.dart';
import 'package:hentai_library/ui/features/shell/views/routing/app_router.dart';
import 'package:hentai_library/ui/features/shell/views/routing/reader_route_args.dart';
import 'package:hentai_library/ui/core/dto/history_grid_item.dart';
import 'package:hentai_library/ui/core/widgets/actions/ghost_button.dart';
import 'package:hentai_library/ui/core/widgets/element/card/reading_history_card.dart';
import 'package:hentai_library/ui/core/widgets/overlays/dialog/confirm/clear_reading_history_confirm_dialog.dart';
import 'package:hentai_library/ui/core/widgets/form/custom_text_field.dart';
import 'package:hentai_library/ui/features/shell/view_models/history_paged_feed_state.dart';
import 'package:hentai_library/ui/features/shell/views/history_page/history_layout_constants.dart';
import 'package:hentai_library/ui/features/shell/views/responsive_app_shell.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

const double _kHistoryLoadMoreThreshold = 400;

class HistoryPage extends ConsumerWidget {
  const HistoryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppThemeTokens tokens = context.tokens;
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double viewportWidth = constraints.maxWidth;
        final HistoryLayoutTier layoutTier = historyLayoutTierForWidth(
          viewportWidth,
        );
        final double horizontalPadding = historyContentHorizontalPadding(
          layoutTier,
        );
        final double innerMaxWidth = historyInnerContentMaxWidth(
          layoutTier,
          viewportWidth,
        );

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
                metrics.pixels >=
                metrics.maxScrollExtent - _kHistoryLoadMoreThreshold;
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
                padding: EdgeInsets.fromLTRB(
                  horizontalPadding,
                  tokens.layout.contentAreaPadding.top,
                  horizontalPadding,
                  0,
                ),
                sliver: SliverToBoxAdapter(
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: SizedBox(
                      width: innerMaxWidth,
                      child: _Header(
                        layoutTier: layoutTier,
                        contentMaxWidth: innerMaxWidth,
                        onOpenNavigation: layoutTier == HistoryLayoutTier.compact
                            ? openAppShellNavigationDrawer
                            : null,
                      ),
                    ),
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 16)),
              SliverPadding(
                padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                sliver: _HistoryListSliver(
                  layoutTier: layoutTier,
                  viewportWidth: viewportWidth,
                  contentMaxWidth: innerMaxWidth,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Header extends ConsumerWidget {
  const _Header({
    required this.layoutTier,
    required this.contentMaxWidth,
    this.onOpenNavigation,
  });

  final HistoryLayoutTier layoutTier;
  final double contentMaxWidth;
  final VoidCallback? onOpenNavigation;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final AppThemeTokens tokens = context.tokens;
    final int totalCount = ref.watch(
      historyPagedFeedControllerProvider.select(
        (AsyncValue<HistoryPagedFeedState> value) =>
            value.asData?.value.totalCount ?? 0,
      ),
    );
    final ContentLayoutTier searchTier = switch (layoutTier) {
      HistoryLayoutTier.compact => ContentLayoutTier.compact,
      HistoryLayoutTier.medium => ContentLayoutTier.medium,
      HistoryLayoutTier.expanded => ContentLayoutTier.expanded,
    };
    final double searchWidth = contentSearchFieldWidth(
      searchTier,
      contentMaxWidth,
    );
    final double titleFontSize = historyPageTitleFontSize(layoutTier);

    final Widget titleSection = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 6,
      children: <Widget>[
        if (onOpenNavigation != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: GhostButton.icon(
              icon: LucideIcons.menu,
              semanticLabel: '打开导航菜单',
              tooltip: '',
              iconSize: 16,
              size: 32,
              borderRadius: 8,
              foregroundColor: theme.colorScheme.hentai.iconDefault,
              hoverColor: theme.hoverColor,
              overlayColor: theme.hoverColor,
              onPressed: onOpenNavigation,
            ),
          ),
        Text(
          '阅读历史',
          style: TextStyle(
            color: theme.colorScheme.hentai.textPrimary,
            fontSize: titleFontSize,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.4,
          ),
        ),
        Text(
          '$totalCount 条记录 • 最长保留 30 天',
          style: TextStyle(
            fontSize: tokens.text.bodySm,
            fontWeight: FontWeight.w400,
            color: theme.colorScheme.hentai.textTertiary,
          ),
        ),
      ],
    );
    final Widget searchField = SizedBox(
      width: searchWidth,
      child: CustomTextField(
        hintText: '搜索历史记录...',
        onChanged: (String value) => ref
            .read(historyPagedFeedControllerProvider.notifier)
            .setKeyword(value),
      ),
    );
    final Widget clearButton = _buildClearBtn(context, ref, totalCount > 0);

    if (historyHeaderIsVertical(layoutTier)) {
      return Container(
        padding: const EdgeInsets.all(2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            titleSection,
            const SizedBox(height: 12),
            searchField,
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: clearButton,
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(2),
      child: Row(
        children: <Widget>[
          titleSection,
          const Spacer(),
          searchField,
          const SizedBox(width: 12),
          clearButton,
        ],
      ),
    );
  }

  Widget _buildClearBtn(BuildContext context, WidgetRef ref, bool enabled) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final Future<void> Function()? onPressed = !enabled
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
          };

    if (historyHeaderUsesIconOnlyClear(layoutTier)) {
      return GhostButton.icon(
        icon: LucideIcons.trash2,
        tooltip: '清空阅读历史',
        semanticLabel: '清空阅读历史',
        onPressed: onPressed,
        iconSize: 16,
        size: 32,
        borderRadius: 8,
        foregroundColor: cs.hentai.warning,
        hoverColor: cs.error.withAlpha(24),
        overlayColor: cs.error.withAlpha(20),
        delayTooltipThreeSeconds: true,
      );
    }

    return GhostButton.iconText(
      icon: LucideIcons.trash2,
      text: '清空',
      tooltip: '清空阅读历史',
      semanticLabel: '清空阅读历史',
      onPressed: onPressed,
      foregroundColor: cs.hentai.warning,
      hoverColor: cs.error.withAlpha(24),
      overlayColor: cs.error.withAlpha(20),
    );
  }
}

class _HistoryListSliver extends ConsumerWidget {
  const _HistoryListSliver({
    required this.layoutTier,
    required this.viewportWidth,
    required this.contentMaxWidth,
  });

  final HistoryLayoutTier layoutTier;
  final double viewportWidth;
  final double contentMaxWidth;

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
                  children: <Widget>[
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

        final HistoryGridMetrics gridMetrics = historyGridMetrics(
          layoutTier,
          viewportWidth,
        );

        return SliverMainAxisGroup(
          slivers: <Widget>[
            SliverLayoutBuilder(
              builder: (BuildContext context, SliverConstraints constraints) {
                final double sideInset =
                    ((constraints.crossAxisExtent - contentMaxWidth) / 2).clamp(
                      0,
                      double.infinity,
                    );
                return SliverPadding(
                  padding: EdgeInsets.symmetric(horizontal: sideInset),
                  sliver: SliverGrid.builder(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: gridMetrics.crossAxisCount,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      mainAxisExtent: gridMetrics.mainAxisExtent,
                    ),
                    itemCount: feed.items.length,
                    itemBuilder: (BuildContext context, int index) {
                      final HistoryGridItem item = feed.items[index];
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
                  ),
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
