part of 'library_page_widgets.dart';

class LibrarySeriesBlock extends ConsumerWidget {
  const LibrarySeriesBlock({
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
    if (displayTarget != LibraryDisplayTarget.series) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }
    final AppThemeTokens tokens = context.tokens;
    final AsyncValue<LibrarySeriesCatalogState> catalogAsync = ref.watch(
      librarySeriesCatalogContentProvider,
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
    final LibrarySeriesCatalogState? catalog = catalogAsync.value;
    if (catalog == null) {
      return const SliverToBoxAdapter(
        child: Center(child: CircularProgressIndicator()),
      );
    }
    final List<Series> series = catalog.items;
    final bool isSeriesTableEmpty = catalog.isSeriesTableEmpty;
    final bool showPagination = catalog.showPagination;
    final LibrarySeriesSortOption sortOption = ref.watch(
      librarySeriesTabSortOptionProvider,
    );
    final LibraryAgeRestrictionFilter ageRestriction = ref.watch(
      librarySeriesTabAgeRestrictionFilterProvider,
    );
    final int pageSize = ref.watch(librarySeriesTabPageSizeProvider);
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
              target: LibraryPaginationTarget.series,
              placement: LibraryPaginationPlacement.top,
            ),
          _LibrarySeriesGridSliver(
            layoutTier: layoutTier,
            series: series,
            isSeriesTableEmpty: isSeriesTableEmpty,
            isReloading: catalogAsync.isLoading,
            positionAnimationKey: sortOption,
            suppressAnimationKey: suppressAnimationKey,
          ),
          if (showPagination)
            const LibraryPaginationBarSliver(
              target: LibraryPaginationTarget.series,
              placement: LibraryPaginationPlacement.bottom,
            ),
        ],
      ),
    );
  }
}

class _LibrarySeriesGridSliver extends StatelessWidget {
  const _LibrarySeriesGridSliver({
    required this.layoutTier,
    required this.series,
    required this.isSeriesTableEmpty,
    required this.positionAnimationKey,
    required this.suppressAnimationKey,
    this.isReloading = false,
  });

  final LibraryLayoutTier layoutTier;
  final List<Series> series;
  final bool isSeriesTableEmpty;
  final Object positionAnimationKey;
  final LibraryCatalogGridSuppressAnimationKey suppressAnimationKey;
  final bool isReloading;

  @override
  Widget build(BuildContext context) {
    if (isReloading && series.isEmpty) {
      return const SliverToBoxAdapter(
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (series.isEmpty) {
      return _LibraryCatalogEmptySliver(
        entity: LibraryDisplayTarget.series,
        isTableEmpty: isSeriesTableEmpty,
      );
    }
    return AnimatedLibraryCatalogGridSliver(
      layoutTier: layoutTier,
      itemCount: series.length,
      positionAnimationKey: positionAnimationKey,
      suppressAnimationKey: suppressAnimationKey,
      itemBuilder: (BuildContext context, int index) {
        final Series s = series[index];
        return Center(
          key: ValueKey<String>('library-series-${s.id}'),
          child: SeriesCard(series: s, onTap: () => _openSeriesDetail(s)),
        );
      },
    );
  }
}

void _openSeriesDetail(Series series) {
  final String encoded = Uri.encodeComponent(series.id);
  appRouter.push('/series/$encoded');
}
