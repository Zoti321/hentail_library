import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/core/l10n/app_localizations_x.dart';
import 'package:hentai_library/ui/core/layout/content_search_width.dart';
import 'package:hentai_library/ui/core/layout/page_content_width_layout.dart';
import 'package:hentai_library/ui/core/theme/theme.dart';
import 'package:hentai_library/ui/core/widgets/feedback/custom_toast.dart';
import 'package:hentai_library/ui/providers.dart';
import 'package:hentai_library/ui/features/shell/views/routing/app_router.dart';
import 'package:hentai_library/ui/features/shell/views/routing/reader_route_args.dart';
import 'package:hentai_library/ui/core/dto/history_grid_item.dart';
import 'package:hentai_library/ui/core/widgets/element/card/reading_history_card.dart';
import 'package:hentai_library/ui/core/widgets/form/custom_text_field.dart';
import 'package:hentai_library/ui/features/shell/view_models/history_paged_feed_state.dart';
import 'package:hentai_library/ui/features/shell/views/history_page/history_layout_constants.dart';
import 'package:hentai_library/ui/features/shell/views/history_page/widgets/history_page_header.dart';
import 'package:hentai_library/ui/features/shell/views/responsive_app_shell.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

const double _kHistoryLoadMoreThreshold = 400;

class HistoryPage extends ConsumerStatefulWidget {
  const HistoryPage({super.key});

  @override
  ConsumerState<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends ConsumerState<HistoryPage> {
  final GlobalKey _headerMeasureKey = GlobalKey();
  double? _headerExtent;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(_measureHeaderExtent);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    WidgetsBinding.instance.addPostFrameCallback(_measureHeaderExtent);
  }

  void _measureHeaderExtent(Duration _) {
    final RenderBox? box =
        _headerMeasureKey.currentContext?.findRenderObject() as RenderBox?;
    if (!mounted || box == null) {
      return;
    }
    final double height = box.size.height;
    if (_headerExtent != height) {
      setState(() => _headerExtent = height);
    }
  }

  @override
  Widget build(BuildContext context) {
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

        final Widget headerSection = HistoryPageHeaderSection(
          layoutTier: layoutTier,
          horizontalPadding: horizontalPadding,
          contentMaxWidth: innerMaxWidth,
          onOpenNavigation: appShellPageNavigationOpener(context),
        );
        final Widget header = KeyedSubtree(
          key: _headerMeasureKey,
          child: headerSection,
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
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: <Widget>[
              if (_headerExtent == null)
                SliverToBoxAdapter(child: header)
              else
                SliverPersistentHeader(
                  pinned: true,
                  delegate: HistoryPinnedHeaderDelegate(
                    extent: _headerExtent!,
                    child: header,
                  ),
                ),
              SliverToBoxAdapter(
                child: PageContentWidthAlign(
                  horizontalPadding: horizontalPadding,
                  maxWidth: innerMaxWidth,
                  child: Padding(
                    padding: EdgeInsets.only(
                      top: tokens.layout.contentVerticalPadding,
                      bottom: tokens.layout.contentAreaPadding.bottom,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        _HistoryBodyLeading(
                          layoutTier: layoutTier,
                          contentMaxWidth: innerMaxWidth,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              _HistoryListSliver(
                layoutTier: layoutTier,
                viewportWidth: viewportWidth,
                horizontalPadding: horizontalPadding,
                contentMaxWidth: innerMaxWidth,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _HistoryBodyLeading extends ConsumerWidget {
  const _HistoryBodyLeading({
    required this.layoutTier,
    required this.contentMaxWidth,
  });

  final HistoryLayoutTier layoutTier;
  final double contentMaxWidth;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final AppThemeTokens tokens = context.tokens;
    final l10n = context.l10n;
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          l10n.historyRecordSummary(totalCount),
          style: TextStyle(
            fontSize: tokens.text.bodySm,
            fontWeight: FontWeight.w400,
            color: theme.colorScheme.hentai.textTertiary,
          ),
        ),
        const SizedBox(height: kHistorySubtitleToSearchSpacing),
        Align(
          alignment: Alignment.centerLeft,
          child: SizedBox(
            width: searchWidth,
            child: CustomTextField(
              hintText: l10n.historySearchHint,
              onChanged: (String value) => ref
                  .read(historyPagedFeedControllerProvider.notifier)
                  .setKeyword(value),
            ),
          ),
        ),
        const SizedBox(height: kHistorySearchToListSpacing),
      ],
    );
  }
}

class _HistoryListSliver extends ConsumerWidget {
  const _HistoryListSliver({
    required this.layoutTier,
    required this.viewportWidth,
    required this.horizontalPadding,
    required this.contentMaxWidth,
  });

  final HistoryLayoutTier layoutTier;
  final double viewportWidth;
  final double horizontalPadding;
  final double contentMaxWidth;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final AppThemeTokens tokens = context.tokens;
    final l10n = context.l10n;
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
              l10n.shellLoadFailed,
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
                      feed.keyword.isEmpty
                          ? l10n.historyEmpty
                          : l10n.historyNoMatch,
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
        final double horizontalInset = pageContentAlignedHorizontalInset(
          viewportWidth: viewportWidth,
          horizontalPadding: horizontalPadding,
          maxWidth: contentMaxWidth,
        );

        return SliverMainAxisGroup(
          slivers: <Widget>[
            SliverPadding(
              padding: EdgeInsets.fromLTRB(
                horizontalInset,
                0,
                horizontalInset,
                tokens.layout.contentAreaPadding.bottom,
              ),
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
        showSuccessToast(context, context.l10n.historyDeletedToast);
      }
    } catch (e) {
      if (context.mounted) {
        showErrorToast(context, e);
      }
    }
  }
}
