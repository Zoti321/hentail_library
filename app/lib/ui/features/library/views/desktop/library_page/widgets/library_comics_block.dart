part of 'library_page_widgets.dart';

class LibraryComicsBlock extends ConsumerWidget {
  const LibraryComicsBlock({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final LibraryDisplayTarget displayTarget = ref.watch(
      libraryDisplayTargetProvider,
    );
    if (displayTarget != LibraryDisplayTarget.comics) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }
    final AppThemeTokens tokens = context.tokens;
    final AsyncValue<LibraryComicsCatalogState> catalogAsync = ref.watch(
      libraryComicsCatalogContentProvider,
    );
    if (catalogAsync.hasError) {
      return catalogAsync.when(
        data: (_) => const SliverToBoxAdapter(child: SizedBox.shrink()),
        loading: () => const SliverToBoxAdapter(
          child: Center(child: CircularProgressIndicator()),
        ),
        error: (Object err, StackTrace stack) => SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text('Error: $err'),
          ),
        ),
      );
    }
    final LibraryComicsCatalogState? catalog = catalogAsync.value;
    if (catalog == null) {
      return const SliverToBoxAdapter(
        child: Center(child: CircularProgressIndicator()),
      );
    }
    final List<Comic> comics = catalog.items;
    final String filterQuery = catalog.filterQuery;
    final bool isComicTableEmpty = catalog.isComicTableEmpty;
    final bool showPagination = catalog.showPagination;
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
            isReloading: catalogAsync.isLoading,
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
    this.isReloading = false,
  });
  final List<Comic> comics;
  final bool isComicTableEmpty;
  final String effectiveQuery;
  final bool isReloading;

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
    if (widget.isReloading && widget.comics.isEmpty) {
      return const SliverToBoxAdapter(
        child: Center(child: CircularProgressIndicator()),
      );
    }
    final String q = widget.effectiveQuery.trim();
    if (widget.comics.isEmpty) {
      return _EmptyLibrarySliver(
        query: q,
        showManagePathsEntry: widget.isComicTableEmpty,
      );
    }
    return SliverGrid.builder(
      gridDelegate: _delegateFor(context),
      itemCount: widget.comics.length,
      itemBuilder: (BuildContext context, int index) {
        final Comic manga = widget.comics[index];
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
  }
}
