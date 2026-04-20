import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hentai_library/config/theme.dart';
import 'package:hentai_library/presentation/dto/history_grid_item_dto.dart';
import 'package:hentai_library/presentation/providers/providers.dart';
import 'package:hentai_library/presentation/ui/desktop/pages/main_content/nav/home_page/widgets/home_page_constants.dart';
import 'package:hentai_library/presentation/ui/desktop/widgets/element/card/reading_history_card.dart';
import 'package:hentai_library/presentation/ui/shared/routing/app_router.dart';
import 'package:hentai_library/presentation/ui/shared/routing/reader_route_args.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class HomePageContinueReadingSection extends ConsumerWidget {
  const HomePageContinueReadingSection({
    super.key,
    required this.enabled,
  });

  final bool enabled;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final AppThemeTokens tokens = context.tokens;
    final ColorScheme colorScheme = theme.colorScheme;
    if (!enabled) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            '继续阅读',
            style: TextStyle(
              fontSize: tokens.text.titleSm,
              fontWeight: FontWeight.w600,
              color: colorScheme.textPrimary,
            ),
          ),
          SizedBox(height: tokens.spacing.sm),
          SizedBox(
            height: continueReadingStripHeight + 8,
            child: const Center(
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        ],
      );
    }
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
      children: <Widget>[
        Text(
          '继续阅读',
          style: TextStyle(
            fontSize: tokens.text.titleSm,
            fontWeight: FontWeight.w600,
            color: colorScheme.textPrimary,
          ),
        ),
        SizedBox(height: tokens.spacing.sm),
        SizedBox(
          height: continueReadingStripHeight + 8,
          child: _ContinueReadingBody(
            loading: loading,
            hasError: hasError,
            visible: visible,
            tokens: tokens,
            colorScheme: colorScheme,
          ),
        ),
      ],
    );
  }
}

class _ContinueReadingBody extends StatelessWidget {
  const _ContinueReadingBody({
    required this.loading,
    required this.hasError,
    required this.visible,
    required this.tokens,
    required this.colorScheme,
  });

  final bool loading;
  final bool hasError;
  final List<HistoryGridItemDto> visible;
  final AppThemeTokens tokens;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (hasError) {
      return Center(
        child: Text(
          '加载失败',
          style: TextStyle(
            fontSize: tokens.text.bodySm,
            color: colorScheme.textSecondary,
          ),
        ),
      );
    }
    if (visible.isEmpty) {
      return Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(LucideIcons.bookOpen, size: 20, color: colorScheme.textTertiary),
            SizedBox(width: tokens.spacing.sm),
            Text(
              '暂无阅读记录，',
              style: TextStyle(
                fontSize: tokens.text.bodySm,
                color: colorScheme.textSecondary,
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
          width: continueReadingItemWidth,
          height: continueReadingStripHeight,
          child: item.map(
            comic: (ComicHistoryGridItemDto comicItem) => ReadingHistoryCard.comic(
              comicId: comicItem.comicId,
              title: comicItem.title,
              lastReadTime: comicItem.lastReadTime,
              pageIndex: comicItem.pageIndex,
              onTap: () => appRouter.pushNamed(
                ReaderRouteArgs.readerRouteName,
                queryParameters: ReaderRouteArgs(
                  comicId: comicItem.comicId,
                  readType: ReaderRouteArgs.readTypeComic,
                ).toQueryParameters(),
              ),
            ),
            series: (SeriesHistoryGridItemDto seriesItem) =>
                ReadingHistoryCard.series(
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
                ),
          ),
        );
      },
    );
  }
}
