part of 'library_page_widgets.dart';

class LibraryComicsBlock extends ConsumerWidget {
  const LibraryComicsBlock({
    super.key,
    required this.layoutTier,
    required this.horizontalPadding,
  });

  final LibraryLayoutTier layoutTier;
  final double horizontalPadding;

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
    final bool isComicTableEmpty = catalog.isComicTableEmpty;
    final bool showPagination = catalog.showPagination;
    final LibraryComicSortOption sortOption = ref.watch(
      libraryComicsTabSortOptionProvider,
    );
    final LibraryAgeRestrictionFilter ageRestriction = ref.watch(
      libraryComicsTabAgeRestrictionFilterProvider,
    );
    final int pageSize = ref.watch(libraryComicsTabPageSizeProvider);
    final LibraryCatalogGridSuppressAnimationKey suppressAnimationKey =
        LibraryCatalogGridSuppressAnimationKey(
          keyword: catalog.filterQuery,
          ageRestriction: ageRestriction,
          page: catalog.pagination.page,
          pageSize: pageSize,
        );
    return SliverPadding(
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
      sliver: SliverMainAxisGroup(
        slivers: <Widget>[
          if (showPagination)
            const LibraryPaginationBarSliver(
              target: LibraryPaginationTarget.comics,
              placement: LibraryPaginationPlacement.top,
            ),
          _LibraryComicsGridSliver(
            layoutTier: layoutTier,
            comics: comics,
            isComicTableEmpty: isComicTableEmpty,
            isReloading: catalogAsync.isLoading,
            positionAnimationKey: sortOption,
            suppressAnimationKey: suppressAnimationKey,
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

class _LibraryComicsGridSliver extends StatelessWidget {
  const _LibraryComicsGridSliver({
    required this.layoutTier,
    required this.comics,
    required this.isComicTableEmpty,
    required this.positionAnimationKey,
    required this.suppressAnimationKey,
    this.isReloading = false,
  });

  final LibraryLayoutTier layoutTier;
  final List<Comic> comics;
  final bool isComicTableEmpty;
  final Object positionAnimationKey;
  final LibraryCatalogGridSuppressAnimationKey suppressAnimationKey;
  final bool isReloading;

  @override
  Widget build(BuildContext context) {
    if (isReloading && comics.isEmpty) {
      return const SliverToBoxAdapter(
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (comics.isEmpty) {
      return _LibraryCatalogEmptySliver(
        entity: LibraryDisplayTarget.comics,
        isTableEmpty: isComicTableEmpty,
      );
    }
    return AnimatedLibraryCatalogGridSliver(
      layoutTier: layoutTier,
      itemCount: comics.length,
      positionAnimationKey: positionAnimationKey,
      suppressAnimationKey: suppressAnimationKey,
      itemBuilder: (BuildContext context, int index) {
        final Comic manga = comics[index];
        return Center(
          key: ValueKey<String>(manga.comicId),
          child: ComicCard(
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
