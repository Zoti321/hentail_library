import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod/misc.dart' show Override;
import 'package:hentai_library/ui/core/theme/theme.dart';
import 'package:hentai_library/domain/models/entity/comic/comic.dart';
import 'package:hentai_library/domain/models/entity/comic/series.dart';
import 'package:hentai_library/domain/models/enums.dart';
import 'package:hentai_library/ui/providers.dart';
import 'package:hentai_library/ui/features/library/views/desktop/library_page/widgets/widgets.dart';
import 'package:hentai_library/ui/core/widgets/responsive_layout/library_blocks_layout.dart';

class SearchedPage extends ConsumerWidget {
  const SearchedPage({super.key, required this.query});
  final String query;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final AppThemeTokens tokens = context.tokens;
    final String trimmedQuery = query.trim();
    final LibraryDisplayTarget displayTarget = ref.watch(
      libraryDisplayTargetProvider,
    );

    final AsyncValue<List<Comic>> searchedComics = ref.watch(
      librarySearchPageComicsProvider(trimmedQuery),
    );
    final AsyncValue<LibrarySeriesViewData> searchedSeriesDataAsync = ref.watch(
      librarySearchPageSeriesViewDataProvider(trimmedQuery),
    );
    final LibrarySeriesViewData searchedSeriesData = searchedSeriesDataAsync
        .maybeWhen(
          data: (LibrarySeriesViewData data) => data,
          orElse: () => const LibrarySeriesViewData(
            headerTotalSeriesWithItemsCount: 0,
            seriesWithItemsCount: 0,
            filteredSeries: <Series>[],
          ),
        );
    final int searchedComicCount = searchedComics.maybeWhen(
      data: (List<Comic> comics) => comics.length,
      orElse: () => 0,
    );
    final int searchedSeriesCount = searchedSeriesData.filteredSeries.length;
    final int searchedResultCount = switch (displayTarget) {
      LibraryDisplayTarget.comics => searchedComicCount,
      LibraryDisplayTarget.series => searchedSeriesCount,
    };
    final AsyncValue<LibraryComicsCatalogState> searchComicsCatalogAsync =
        searchedComics.when(
          data: (List<Comic> comics) => AsyncData(
            LibraryComicsCatalogState(
              items: comics,
              pagination: LibraryPagination(
                page: 1,
                totalPages: comics.isNotEmpty ? 1 : 0,
                totalCount: comics.length,
                isLoading: false,
              ),
              filterQuery: trimmedQuery,
              hasReceivedFirstEmit: true,
              isComicTableEmpty: comics.isEmpty,
              showPagination: false,
            ),
          ),
          loading: () => const AsyncLoading<LibraryComicsCatalogState>(),
          error: (Object error, StackTrace stackTrace) =>
              AsyncError<LibraryComicsCatalogState>(error, stackTrace),
        );
    final AsyncValue<LibrarySeriesCatalogState> searchSeriesCatalogAsync =
        searchedSeriesDataAsync.when(
          data: (LibrarySeriesViewData seriesData) => AsyncData(
            LibrarySeriesCatalogState(
              items: seriesData.filteredSeries,
              pagination: LibraryPagination(
                page: 1,
                totalPages: seriesData.filteredSeries.isNotEmpty ? 1 : 0,
                totalCount: seriesData.filteredSeries.length,
                isLoading: false,
              ),
              filterQuery: trimmedQuery,
              showPagination: false,
            ),
          ),
          loading: () => const AsyncLoading<LibrarySeriesCatalogState>(),
          error: (Object error, StackTrace stackTrace) =>
              AsyncError<LibrarySeriesCatalogState>(error, stackTrace),
        );

    return CustomScrollView(
      slivers: <Widget>[
        SliverToBoxAdapter(
          child: Padding(
            padding: tokens.layout.contentAreaPadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  '搜索结果',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.hentai.textPrimary,
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: <Widget>[
                    Text(
                      trimmedQuery.isEmpty ? '请输入关键词进行搜索' : '关键词：$trimmedQuery',
                      style: TextStyle(
                        fontSize: 13,
                        color: theme.colorScheme.hentai.textTertiary,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: theme.colorScheme.hentai.borderSubtle,
                        ),
                      ),
                      child: Text(
                        '$searchedResultCount 个结果',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.hentai.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
                if (trimmedQuery.isNotEmpty) ...<Widget>[
                  const SizedBox(height: 12),
                  LibrarySearchField(initialQuery: trimmedQuery),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: LibraryDisplayTargetTabs(
                      showCountBadges: !libraryHeaderShowsCountChips(context),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        if (trimmedQuery.isEmpty)
          const SliverFillRemaining(
            hasScrollBody: false,
            child: Center(child: Text('请输入关键词后按回车搜索')),
          )
        else ...<Widget>[
          ProviderScope(
            overrides: <Override>[
              libraryComicsCatalogContentProvider.overrideWithValue(
                searchComicsCatalogAsync,
              ),
              librarySeriesCatalogContentProvider.overrideWithValue(
                searchSeriesCatalogAsync,
              ),
            ],
            child: const LibraryBlocksSliverGroup(
              seriesBlock: LibrarySeriesBlock(),
              comicsBlock: LibraryComicsBlock(),
            ),
          ),
        ],
      ],
    );
  }
}
