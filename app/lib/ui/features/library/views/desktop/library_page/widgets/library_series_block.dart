part of 'library_page_widgets.dart';

class LibrarySeriesBlock extends ConsumerWidget {
  const LibrarySeriesBlock({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppThemeTokens tokens = context.tokens;
    final LibraryPageViewModel vm = ref.watch(libraryPageViewModelProvider);
    if (vm.displayTarget != LibraryDisplayTarget.series) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }
    final AsyncValue<List<Series>> seriesAsync = vm.seriesAsync;
    final String filterQuery = vm.filterQuery;
    final bool showPagination = vm.showPagination;
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
            seriesAsync: seriesAsync,
            effectiveQuery: filterQuery,
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
    required this.seriesAsync,
    required this.effectiveQuery,
  });
  final AsyncValue<List<Series>> seriesAsync;
  final String effectiveQuery;

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
    return widget.seriesAsync.when(
      data: (List<Series> series) {
        final String q = widget.effectiveQuery.trim();
        if (series.isEmpty) {
          return _NoMatchingSeriesSliver(query: q);
        }
        return Consumer(
          builder: (BuildContext context, WidgetRef ref, Widget? child) {
            return SliverGrid.builder(
              gridDelegate: _delegateFor(context),
              itemCount: series.length,
              itemBuilder: (BuildContext context, int index) {
                final Series s = series[index];
                return Center(
                  child: SeriesCard(
                    key: Key('library-series-${s.name}'),
                    series: s,
                    size: const Size(double.infinity, double.infinity),
                    onTap: () => _openSeriesDetail(s),
                  ),
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
      loading: () => const SliverToBoxAdapter(
        child: Center(child: CircularProgressIndicator()),
      ),
      skipLoadingOnReload: true,
    );
  }
}

class _NoMatchingSeriesSliver extends StatelessWidget {
  const _NoMatchingSeriesSliver({this.query = ''});
  final String query;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final String q = query.trim();
    final bool hasQuery = q.isNotEmpty;
    final String message = hasQuery ? '无匹配系列' : '暂无系列';
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.only(top: 24, bottom: 48),
        child: Center(
          child: Text(
            message,
            style: TextStyle(
              fontSize: 13,
              color: theme.colorScheme.hentai.textTertiary,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}

void _openSeriesDetail(Series series) {
  final String encoded = Uri.encodeComponent(series.id);
  appRouter.push('/series/$encoded');
}
