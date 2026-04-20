part of 'library_page_widgets.dart';

class LibrarySeriesBlock extends ConsumerWidget {
  const LibrarySeriesBlock({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final LibraryDisplayTarget displayTarget = ref.watch(
      libraryPageProvider.select((LibraryPageState s) => s.effectiveFilter.displayTarget),
    );
    final bool showSeriesSection = displayTarget != LibraryDisplayTarget.comics;
    final bool showComicsSection = displayTarget != LibraryDisplayTarget.series;
    final LibrarySeriesViewData seriesData = ref.watch(librarySeriesViewDataProvider);
    final List<Series> seriesToShow = seriesData.filteredSeries;
    final String filterQuery = ref.watch(
      libraryPageProvider.select((LibraryPageState s) => s.effectiveFilter.query ?? ''),
    );
    if (!showSeriesSection) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }
    if (seriesToShow.isEmpty) {
      if (!showComicsSection) {
        return _NoMatchingSeriesSliver(query: filterQuery);
      }
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }
    final bool isGridView = ref.watch(
      libraryPageProvider.select((LibraryPageState s) => s.isGridView),
    );
    return SliverMainAxisGroup(
      slivers: <Widget>[
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 4),
            child: Text(
              '系列',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.textSecondary,
              ),
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 48),
          sliver: isGridView
              ? _LibrarySeriesGridSliver(series: seriesToShow)
              : _LibrarySeriesListSliver(series: seriesToShow),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 16)),
      ],
    );
  }
}

class _LibrarySeriesGridSliver extends StatefulWidget {
  const _LibrarySeriesGridSliver({required this.series});
  final List<Series> series;

  @override
  State<_LibrarySeriesGridSliver> createState() => _LibrarySeriesGridSliverState();
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
    return SliverGrid.builder(
      gridDelegate: _delegateFor(context),
      itemCount: widget.series.length,
      itemBuilder: (BuildContext context, int index) {
        final Series s = widget.series[index];
        return Center(
          child: SeriesCard(
            key: Key('library-series-${s.name}'),
            series: s,
            size: const Size(double.infinity, double.infinity),
            onTap: () {
              appRouter.pushNamed(
                '系列详情',
                pathParameters: <String, String>{'name': s.name},
              );
            },
          ),
        );
      },
    );
  }
}

class _LibrarySeriesListSliver extends StatelessWidget {
  const _LibrarySeriesListSliver({required this.series});
  final List<Series> series;

  @override
  Widget build(BuildContext context) {
    return SliverList.separated(
      itemCount: series.length,
      separatorBuilder: (BuildContext context, int index) => const SizedBox(height: 8),
      itemBuilder: (BuildContext context, int index) {
        final Series s = series[index];
        return SeriesTile(
          key: Key('library-series-${s.name}'),
          series: s,
          onTap: () {
            appRouter.pushNamed(
              '系列详情',
              pathParameters: <String, String>{'name': s.name},
            );
          },
          onSecondaryTapDown: (_) {},
        );
      },
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
              color: theme.colorScheme.textTertiary,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
