import 'package:flutter/material.dart';
import 'package:hentai_library/features/home/presentation/view_models/history_paged_feed_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/core/l10n/app_localizations_x.dart';
import 'package:hentai_library/shared/ui/layout/content_search_width.dart';
import 'package:hentai_library/shared/ui/layout/page_content_width_layout.dart';
import 'package:hentai_library/shared/ui/theme/theme.dart';
import 'package:hentai_library/shared/ui/widgets/feedback/custom_toast.dart';
import 'package:hentai_library/shared/di/read_session_launch_providers.dart';
import 'package:hentai_library/shared/ui/layout/catalog_grid_visible_range.dart';
import 'package:hentai_library/shared/ui/dto/history_grid_item.dart';
import 'package:hentai_library/shared/ui/widgets/element/card/reading_history_card.dart';
import 'package:hentai_library/shared/ui/widgets/form/custom_text_field.dart';
import 'package:hentai_library/features/home/presentation/view_models/history_cover_viewport_notifier.dart';
import 'package:hentai_library/features/home/presentation/view_models/history_load_more_throttle.dart';
import 'package:hentai_library/features/home/presentation/view_models/history_paged_feed_state.dart';
import 'package:hentai_library/shared/ui/layout/page_header_layout.dart';
import 'package:hentai_library/features/home/presentation/views/history_page/widgets/history_page_header.dart';
import 'package:hentai_library/shared/ui/layout/page_pinned_header_delegate.dart';
import 'package:hentai_library/shared/ui/layout/app_shell_navigation.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

const double _kHistoryLoadMoreThreshold = 400;
const double _kHistoryGridMainAxisSpacing = 12;

class HistoryPage extends ConsumerStatefulWidget {
  const HistoryPage({super.key});

  @override
  ConsumerState<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends ConsumerState<HistoryPage> {
  final GlobalKey _headerMeasureKey = GlobalKey();
  double? _headerExtent;
  DateTime? _lastLoadMoreAttemptAt;

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
        final PageHeaderLayoutTier layoutTier = pageHeaderLayoutTierForWidth(
          viewportWidth,
        );
        final double horizontalPadding = pageHeaderHorizontalPadding(
          layoutTier,
        );
        final double innerMaxWidth = pageHeaderInnerMaxWidth(
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
            if (notification is! ScrollUpdateNotification &&
                notification is! ScrollEndNotification) {
              return false;
            }
            final ScrollMetrics metrics = notification.metrics;
            final HistoryPagedFeedState? feed = ref
                .read(historyPagedFeedControllerProvider)
                .asData
                ?.value;
            final int itemCount = feed?.items.length ?? 0;
            if (itemCount > 0) {
              final PageHeaderGridMetrics gridMetrics = pageHeaderGridMetrics(
                layoutTier,
                viewportWidth,
              );
              final ({int startIndex, int endIndex}) range =
                  visibleCatalogGridIndexRange(
                    scrollPixels: metrics.pixels,
                    viewportHeight: metrics.viewportDimension,
                    gridStartScrollOffset: 0,
                    itemCount: itemCount,
                    rowExtent: gridMetrics.mainAxisExtent,
                    rowSpacing: _kHistoryGridMainAxisSpacing,
                    crossAxisCount: gridMetrics.crossAxisCount,
                    rowBuffer: 2,
                  );
              ref
                  .read(historyCoverViewportProvider.notifier)
                  .updateRange(
                    startIndex: range.startIndex,
                    endIndex: range.endIndex,
                  );
            }
            if (notification is! ScrollUpdateNotification) {
              return false;
            }
            if (metrics.maxScrollExtent <= 0) {
              return false;
            }
            final bool nearBottom =
                metrics.pixels >=
                metrics.maxScrollExtent - _kHistoryLoadMoreThreshold;
            if (!nearBottom) {
              return false;
            }
            final DateTime now = DateTime.now();
            if (!shouldAttemptHistoryLoadMore(
              lastAttemptAt: _lastLoadMoreAttemptAt,
              now: now,
            )) {
              return false;
            }
            _lastLoadMoreAttemptAt = now;
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
                  delegate: PagePinnedHeaderDelegate(
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

  final PageHeaderLayoutTier layoutTier;
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
      PageHeaderLayoutTier.compact => ContentLayoutTier.compact,
      PageHeaderLayoutTier.medium => ContentLayoutTier.medium,
      PageHeaderLayoutTier.expanded => ContentLayoutTier.expanded,
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
        const SizedBox(height: kPageHeaderSubtitleToSearchSpacing),
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
        const SizedBox(height: kPageHeaderSearchToListSpacing),
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

  final PageHeaderLayoutTier layoutTier;
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

        final PageHeaderGridMetrics gridMetrics = pageHeaderGridMetrics(
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
                  mainAxisSpacing: _kHistoryGridMainAxisSpacing,
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
                    gridIndex: index,
                    coverViewport: historyCoverViewportProvider,
                    onTap: () => ref
                        .read(readSessionLaunchPortProvider)
                        .openComic(comicId: item.comicId),
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
      await ref
          .read(historyPagedFeedControllerProvider.notifier)
          .deleteHistory(comicId);
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
