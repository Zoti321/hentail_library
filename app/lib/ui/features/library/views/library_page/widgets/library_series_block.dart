part of 'library_page_widgets.dart';

class LibrarySeriesBlock extends ConsumerWidget {
  const LibrarySeriesBlock({super.key});

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
    return SliverPadding(
      padding: EdgeInsets.symmetric(
        horizontal: tokens.layout.contentHorizontalPadding,
      ),
      sliver: SliverMainAxisGroup(
        slivers: <Widget>[
          if (showPagination)
            const LibraryPaginationBarSliver(
              target: LibraryPaginationTarget.series,
              placement: LibraryPaginationPlacement.top,
            ),
          _LibrarySeriesGridSliver(
            series: series,
            isSeriesTableEmpty: isSeriesTableEmpty,
            isReloading: catalogAsync.isLoading,
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

class _LibrarySeriesGridSliver extends StatefulWidget {
  const _LibrarySeriesGridSliver({
    required this.series,
    required this.isSeriesTableEmpty,
    this.isReloading = false,
  });
  final List<Series> series;
  final bool isSeriesTableEmpty;
  final bool isReloading;

  @override
  State<_LibrarySeriesGridSliver> createState() =>
      _LibrarySeriesGridSliverState();
}

class _LibrarySeriesGridSliverState extends State<_LibrarySeriesGridSliver> {
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
    if (widget.isReloading && widget.series.isEmpty) {
      return const SliverToBoxAdapter(
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (widget.series.isEmpty) {
      return _LibraryCatalogEmptySliver(
        entity: LibraryDisplayTarget.series,
        isTableEmpty: widget.isSeriesTableEmpty,
      );
    }
    return SliverGrid.builder(
      gridDelegate: _delegateFor(context),
      itemCount: widget.series.length,
      itemBuilder: (BuildContext context, int index) {
        final Series s = widget.series[index];
        return Center(
          child: SeriesCard(
            key: Key('library-series-${s.id}'),
            series: s,
            size: const Size(double.infinity, double.infinity),
            onTap: () => _openSeriesDetail(s),
          ),
        );
      },
    );
  }
}

void _openSeriesDetail(Series series) {
  final String encoded = Uri.encodeComponent(series.id);
  appRouter.push('/series/$encoded');
}
