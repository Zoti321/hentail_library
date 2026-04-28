import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/theme/theme.dart';
import 'package:hentai_library/model/entity/comic/comic.dart';
import 'package:hentai_library/model/entity/comic/series.dart';
import 'package:hentai_library/presentation/providers/providers.dart';
import 'package:hentai_library/presentation/ui/desktop/pages/main_content/nav/library_page/widgets/widgets.dart';
import 'package:hentai_library/presentation/ui/desktop/widgets/responsive_layout/library_blocks_layout.dart';

class SearchedPage extends ConsumerWidget {
  const SearchedPage({super.key, required this.query});
  final String query;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final String trimmedQuery = query.trim();

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
    final int searchedResultCount = searchedComicCount + searchedSeriesCount;
    final LibraryPageViewModel searchedViewModel = LibraryPageViewModel(
      comicsAsync: searchedComics,
      seriesViewData: searchedSeriesData,
      displayedComicCount: searchedComicCount,
      displayedSeriesCount: searchedSeriesCount,
      isGridView: ref.watch(libraryIsGridViewProvider),
      displayTarget: ref.watch(libraryDisplayTargetProvider),
      filterQuery: trimmedQuery,
      hasReceivedFirstEmit: true,
      isComicTableEmpty: searchedResultCount == 0,
    );

    return CustomScrollView(
      slivers: <Widget>[
        // header
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(48, 20, 48, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  '搜索结果',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.textPrimary,
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
                        color: theme.colorScheme.textTertiary,
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
                          color: theme.colorScheme.borderSubtle,
                        ),
                      ),
                      child: Text(
                        '$searchedResultCount 个结果',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
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
            overrides: [
              libraryPageViewModelProvider.overrideWithValue(searchedViewModel),
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
