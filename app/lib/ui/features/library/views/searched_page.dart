import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hentai_library/domain/models/entity/comic/comic.dart';
import 'package:hentai_library/domain/models/entity/comic/series.dart';
import 'package:hentai_library/ui/core/theme/theme.dart';
import 'package:hentai_library/ui/core/widgets/element/card/comic_card.dart';
import 'package:hentai_library/ui/core/widgets/element/card/series_card.dart';
import 'package:hentai_library/ui/features/library/views/library_page/widgets/widgets.dart';
import 'package:hentai_library/ui/features/library/views/searched_page/widgets/search_result_horizontal_section.dart';
import 'package:hentai_library/ui/features/library/views/searched_page/widgets/searched_page_header.dart';
import 'package:hentai_library/ui/features/shell/views/routing/app_router.dart';
import 'package:hentai_library/ui/features/shell/views/routing/reader_route_args.dart';
import 'package:hentai_library/ui/providers.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

const double kSearchResultCardWidth = 200;

class SearchedPage extends ConsumerStatefulWidget {
  const SearchedPage({super.key, required this.query});

  final String query;

  @override
  ConsumerState<SearchedPage> createState() => _SearchedPageState();
}

class _SearchedPageState extends ConsumerState<SearchedPage> {
  final GlobalKey _headerMeasureKey = GlobalKey();
  double? _headerExtent;

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
    final ColorScheme cs = Theme.of(context).colorScheme;
    final String trimmedQuery = widget.query.trim();

    final AsyncValue<List<Comic>> searchedComics = ref.watch(
      librarySearchPageComicsProvider(trimmedQuery),
    );
    final AsyncValue<LibrarySeriesViewData> searchedSeriesDataAsync = ref.watch(
      librarySearchPageSeriesViewDataProvider(trimmedQuery),
    );

    final List<Comic> comics = searchedComics.maybeWhen(
      data: (List<Comic> value) => value,
      orElse: () => const <Comic>[],
    );
    final List<Series> series = searchedSeriesDataAsync.maybeWhen(
      data: (LibrarySeriesViewData value) => value.filteredSeries,
      orElse: () => const <Series>[],
    );

    final int searchedComicCount = comics.length;
    final int searchedSeriesCount = series.length;
    final int totalResultCount = searchedComicCount + searchedSeriesCount;

    final bool isLoading =
        searchedComics.isLoading || searchedSeriesDataAsync.isLoading;
    final bool hasResolvedData =
        searchedComics.hasValue && searchedSeriesDataAsync.hasValue;
    final bool hasError =
        searchedComics.hasError || searchedSeriesDataAsync.hasError;
    final Object? error = searchedComics.error ?? searchedSeriesDataAsync.error;

    final double cardHeight = libraryGridMainAxisExtentFromTokens(tokens);
    final Widget headerSection = trimmedQuery.isEmpty
        ? SearchedPageHeaderSection(
            query: '搜索结果',
            resultCount: 0,
            showQuotes: false,
          )
        : SearchedPageHeaderSection(
            query: trimmedQuery,
            resultCount: totalResultCount,
          );
    final Widget header = KeyedSubtree(
      key: _headerMeasureKey,
      child: headerSection,
    );

    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: <Widget>[
        if (_headerExtent == null)
          SliverToBoxAdapter(
            child: header,
          )
        else
          SliverPersistentHeader(
            pinned: true,
            delegate: LibraryPinnedHeaderDelegate(
              extent: _headerExtent!,
              child: header,
            ),
          ),
        SliverPadding(
          padding: EdgeInsets.fromLTRB(
            tokens.layout.contentHorizontalPadding,
            tokens.layout.contentVerticalPadding + kLibrarySearchToGridSpacing,
            tokens.layout.contentHorizontalPadding,
            tokens.layout.contentVerticalPadding,
          ),
          sliver: SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: tokens.spacing.lg,
              children: <Widget>[
                if (trimmedQuery.isNotEmpty) ...<Widget>[
                  LibrarySearchField(initialQuery: trimmedQuery),
                  if (isLoading && !hasResolvedData)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 48),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (hasError && !hasResolvedData)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Text(
                        '加载失败：$error',
                        style: TextStyle(
                          fontSize: 13,
                          color: cs.error,
                        ),
                      ),
                    )
                  else if (searchedSeriesCount == 0 && searchedComicCount == 0)
                    _SearchResultsEmptyState(
                      onGoToLibrary: () => context.go('/local'),
                    )
                  else ...<Widget>[
                    if (searchedSeriesCount > 0)
                      SearchResultHorizontalSection(
                        title: '系列',
                        itemCount: series.length,
                        itemHeight: cardHeight,
                        itemBuilder: (BuildContext context, int index) {
                          final Series item = series[index];
                          return SizedBox(
                            width: kSearchResultCardWidth,
                            child: SeriesCard(
                              key: Key('search-series-${item.id}'),
                              series: item,
                              size: const Size(
                                kSearchResultCardWidth,
                                double.infinity,
                              ),
                              onTap: () {
                                final String encoded = Uri.encodeComponent(
                                  item.id,
                                );
                                appRouter.push('/series/$encoded');
                              },
                            ),
                          );
                        },
                      ),
                    if (searchedComicCount > 0)
                      SearchResultHorizontalSection(
                        title: '漫画',
                        itemCount: comics.length,
                        itemHeight: cardHeight,
                        itemBuilder: (BuildContext context, int index) {
                          final Comic comic = comics[index];
                          return SizedBox(
                            width: kSearchResultCardWidth,
                            child: ComicCard(
                              key: Key('search-comic-${comic.comicId}'),
                              comic: comic,
                              size: const Size(
                                kSearchResultCardWidth,
                                double.infinity,
                              ),
                              onTap: () {
                                appRouter.pushNamed(
                                  '漫画详情',
                                  pathParameters: <String, String>{
                                    'id': comic.comicId,
                                  },
                                );
                              },
                              onPlay: () {
                                appRouter.pushNamed(
                                  ReaderRouteArgs.readerRouteName,
                                  queryParameters: ReaderRouteArgs(
                                    comicId: comic.comicId,
                                  ).toQueryParameters(),
                                );
                              },
                            ),
                          );
                        },
                      ),
                  ],
                ],
              ],
            ),
          ),
        ),
        if (trimmedQuery.isEmpty)
          const SliverFillRemaining(
            hasScrollBody: false,
            child: Center(child: Text('请输入关键词后按回车搜索')),
          ),
      ],
    );
  }
}

class _SearchResultsEmptyState extends StatelessWidget {
  const _SearchResultsEmptyState({required this.onGoToLibrary});

  final VoidCallback onGoToLibrary;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final AppThemeTokens tokens = context.tokens;
    return Padding(
      padding: EdgeInsets.symmetric(vertical: tokens.spacing.xl * 2),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: tokens.spacing.md,
          children: <Widget>[
            Icon(
              LucideIcons.searchX,
              size: 40,
              color: cs.hentai.textTertiary,
            ),
            Text(
              '无匹配结果',
              style: TextStyle(
                fontSize: tokens.text.bodyMd,
                color: cs.hentai.textSecondary,
              ),
            ),
            TextButton.icon(
              onPressed: onGoToLibrary,
              icon: const Icon(LucideIcons.library, size: 16),
              label: const Text('返回漫画库'),
            ),
          ],
        ),
      ),
    );
  }
}
