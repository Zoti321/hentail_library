part of 'library_page_widgets.dart';

class LibraryComicsBlock extends ConsumerWidget {
  const LibraryComicsBlock({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppThemeTokens tokens = context.tokens;
    final LibraryPageViewModel vm = ref.watch(libraryPageViewModelProvider);
    if (vm.displayTarget != LibraryDisplayTarget.comics) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }
    final AsyncValue<List<Comic>> comics = vm.comicsAsync;
    final String filterQuery = vm.filterQuery;
    final bool isComicTableEmpty = vm.isComicTableEmpty;
    final bool showPagination = vm.showPagination;
    return SliverPadding(
      padding: EdgeInsets.symmetric(
        horizontal: tokens.layout.contentHorizontalPadding,
      ),
      sliver: SliverMainAxisGroup(
        slivers: <Widget>[
          if (showPagination)
            const LibraryPaginationBarSliver(
              target: LibraryPaginationTarget.comics,
              placement: LibraryPaginationPlacement.top,
            ),
          _LibraryComicsGridSliver(
            comics: comics,
            isComicTableEmpty: isComicTableEmpty,
            effectiveQuery: filterQuery,
          ),
          if (showPagination)
            const LibraryPaginationBarSliver(
              target: LibraryPaginationTarget.comics,
              placement: LibraryPaginationPlacement.bottom,
            ),
        ],
      ),
    );
  }
}

class _LibraryComicsGridSliver extends StatefulWidget {
  const _LibraryComicsGridSliver({
    required this.comics,
    required this.isComicTableEmpty,
    required this.effectiveQuery,
  });
  final AsyncValue<List<Comic>> comics;
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
