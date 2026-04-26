part of 'library_page_widgets.dart';

class LibraryComicsBlock extends ConsumerWidget {
  const LibraryComicsBlock({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final LibraryPageViewModel vm = ref.watch(libraryPageViewModelProvider);
    final LibraryDisplayTarget displayTarget = vm.displayTarget;
    final bool showComicsSection = displayTarget != LibraryDisplayTarget.series;
    if (!showComicsSection) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }
    final AsyncValue<List<Comic>> comics = vm.comicsAsync;
    final LibrarySeriesViewData seriesData = vm.seriesViewData;
    final bool showSeriesSection = displayTarget != LibraryDisplayTarget.comics;
    final bool hasSeriesSection =
        showSeriesSection && seriesData.filteredSeries.isNotEmpty;
    final String filterQuery = vm.filterQuery;
    final bool isComicTableEmpty = vm.isComicTableEmpty;
    final bool isGridView = vm.isGridView;
    return LibrarySectionSliver(
      title: '漫画',
      contentSliver: LibraryAdaptiveItemsSliver(
        isGridView: isGridView,
        gridSliver: _LibraryComicsGridSliver(
          comics: comics,
          hasSeriesSection: hasSeriesSection,
          isComicTableEmpty: isComicTableEmpty,
          effectiveQuery: filterQuery,
        ),
        listSliver: _LibraryComicsListSliver(
          comics: comics,
          hasSeriesSection: hasSeriesSection,
          isComicTableEmpty: isComicTableEmpty,
          effectiveQuery: filterQuery,
        ),
      ),
    );
  }
}

class _LibraryComicsGridSliver extends StatefulWidget {
  const _LibraryComicsGridSliver({
    required this.comics,
    required this.hasSeriesSection,
    required this.isComicTableEmpty,
    required this.effectiveQuery,
  });
  final AsyncValue<List<Comic>> comics;
  final bool hasSeriesSection;
  final bool isComicTableEmpty;
  final String effectiveQuery;

  @override
  State<_LibraryComicsGridSliver> createState() =>
      _LibraryComicsGridSliverState();
}

class _LibraryComicsGridSliverState extends State<_LibraryComicsGridSliver> {
  AppThemeTokens? _lastTokens;
  SliverGridDelegate? _cachedDelegate;

  SliverGridDelegate _delegateFor(BuildContext context) {
    final AppThemeTokens tokens = context.tokens;
    if (_cachedDelegate != null && _lastTokens == tokens) {
      return _cachedDelegate!;
    }
    _lastTokens = tokens;
    return _cachedDelegate = libraryGridDelegateForTokens(tokens);
  }

  @override
  Widget build(BuildContext context) {
    return widget.comics.when(
      data: (List<Comic> comics) {
        final String q = widget.effectiveQuery.trim();
        if (comics.isEmpty) {
          if (widget.hasSeriesSection) {
            return _NoMatchingComicsSliver(
              query: q,
              showManagePathsEntry: widget.isComicTableEmpty,
            );
          }
          return _EmptyLibrarySliver(
            query: q,
            showManagePathsEntry: widget.isComicTableEmpty,
          );
        }
        return SliverGrid.builder(
          gridDelegate: _delegateFor(context),
          itemCount: comics.length,
          itemBuilder: (BuildContext context, int index) {
            final Comic manga = comics[index];
            return Center(
              child: ComicCard(
                key: Key(manga.comicId),
                comic: manga,
                size: const Size(double.infinity, double.infinity),
                onTap: () {
                  appRouter.pushNamed(
                    '漫画详情',
                    pathParameters: <String, String>{'id': manga.comicId},
                  );
                },
                onPlay: () {},
              ),
            );
          },
        );
      },
      error: (Object err, StackTrace stack) => SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text('Error: $err'),
        ),
      ),
      loading: () => const SliverToBoxAdapter(
        child: Center(child: CircularProgressIndicator()),
      ),
      skipLoadingOnReload: true,
    );
  }
}

class _LibraryComicsListSliver extends StatelessWidget {
  const _LibraryComicsListSliver({
    required this.comics,
    required this.hasSeriesSection,
    required this.isComicTableEmpty,
    required this.effectiveQuery,
  });
  final AsyncValue<List<Comic>> comics;
  final bool hasSeriesSection;
  final bool isComicTableEmpty;
  final String effectiveQuery;

  @override
  Widget build(BuildContext context) {
    return comics.when(
      data: (List<Comic> comics) {
        final String q = effectiveQuery.trim();
        if (comics.isEmpty) {
          if (hasSeriesSection) {
            return _NoMatchingComicsSliver(
              query: q,
              showManagePathsEntry: isComicTableEmpty,
            );
          }
          return _EmptyLibrarySliver(
            query: q,
            showManagePathsEntry: isComicTableEmpty,
          );
        }
        return SliverList.separated(
          itemCount: comics.length,
          separatorBuilder: (BuildContext ctx, int i) =>
              const SizedBox(height: 8),
          itemBuilder: (BuildContext context, int index) {
            final Comic manga = comics[index];
            return ComicTile(
              key: Key(manga.comicId),
              comic: manga,
              onTap: () {
                appRouter.pushNamed(
                  '漫画详情',
                  pathParameters: <String, String>{'id': manga.comicId},
                );
              },
            );
          },
        );
      },
      error: (Object err, StackTrace stack) => SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text('Error: $err'),
        ),
      ),
      loading: () => const SliverFillRemaining(
        hasScrollBody: false,
        child: Center(child: CircularProgressIndicator()),
      ),
      skipLoadingOnReload: true,
    );
  }
}
