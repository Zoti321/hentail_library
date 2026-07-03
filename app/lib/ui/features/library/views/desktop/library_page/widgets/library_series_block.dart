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
    final LibrarySeriesViewData seriesData = vm.seriesViewData;
    final List<Series> seriesToShow = seriesData.filteredSeries;
    final String filterQuery = vm.filterQuery;
    if (seriesToShow.isEmpty) {
      return _NoMatchingSeriesSliver(query: filterQuery);
    }
    return SliverPadding(
      padding: EdgeInsets.symmetric(
        horizontal: tokens.layout.contentHorizontalPadding,
      ),
      sliver: _LibrarySeriesGridSliver(series: seriesToShow),
    );
  }
}

class _LibrarySeriesGridSliver extends StatefulWidget {
  const _LibrarySeriesGridSliver({required this.series});
  final List<Series> series;

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
    return Consumer(
      builder: (BuildContext context, WidgetRef ref, Widget? child) {
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
                onTap: () => _openSeriesDetail(s),
                onSecondaryTapDown: (TapDownDetails details) {
                  _showSeriesContextMenu(
                    context: context,
                    ref: ref,
                    series: s,
                    globalPosition: details.globalPosition,
                  );
                },
              ),
            );
          },
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
  appRouter.pushNamed(
    '系列详情',
    pathParameters: <String, String>{'name': series.name},
  );
}

void _showSeriesContextMenu({
  required BuildContext context,
  required WidgetRef ref,
  required Series series,
  required Offset globalPosition,
}) {
  final RenderBox overlay =
      Overlay.of(context).context.findRenderObject() as RenderBox;
  final Offset relativePosition = overlay.globalToLocal(globalPosition);
  SeriesContextMenu.show(
    context,
    position: relativePosition,
    seriesName: series.name,
    onAction: (SeriesContextAction action) {
      _handleSeriesContextAction(
        context: context,
        ref: ref,
        series: series,
        action: action,
      );
    },
  );
}

Future<void> _handleSeriesContextAction({
  required BuildContext context,
  required WidgetRef ref,
  required Series series,
  required SeriesContextAction action,
}) async {
  switch (action) {
    case SeriesContextAction.read:
      await _openSeriesReader(context: context, ref: ref, series: series);
      return;
    case SeriesContextAction.reorder:
      if (series.items.length < 2) {
        showInfoToast(context, '至少需要 2 本漫画才能调整顺序');
        return;
      }
      await showDialog<void>(
        context: context,
        builder: (BuildContext context) =>
            ReorderSeriesItemsDialog(series: series),
      );
      return;
    case SeriesContextAction.addComics:
      await showDialog<void>(
        context: context,
        builder: (BuildContext context) => AddComicsToSeriesDialog(
          key: ValueKey<String>(series.name),
          series: series,
        ),
      );
      return;
    case SeriesContextAction.rename:
      final String? newName = await showDialog<String>(
        context: context,
        builder: (BuildContext context) => RenameSeriesDialog(series: series),
      );
      if (newName != null && context.mounted) {
        showSuccessToast(context, '已重命名');
      }
      return;
    case SeriesContextAction.delete:
      final bool confirmed =
          await showDialog<bool>(
            context: context,
            builder: (BuildContext context) =>
                SeriesConfirmDeleteDialog(series: series),
          ) ??
          false;
      if (!confirmed || !context.mounted) {
        return;
      }
      try {
        await ref.read(seriesActionsProvider).delete(series.name);
        if (context.mounted) {
          showSuccessToast(context, '已删除系列');
        }
      } catch (error) {
        if (context.mounted) {
          showErrorToast(context, error);
        }
      }
      return;
  }
}

Future<void> _openSeriesReader({
  required BuildContext context,
  required WidgetRef ref,
  required Series series,
}) async {
  final List<SeriesItem> sortedItems = List<SeriesItem>.from(series.items)
    ..sort((SeriesItem a, SeriesItem b) => a.order.compareTo(b.order));
  if (sortedItems.isEmpty) {
    showInfoToast(context, '系列内暂无漫画');
    return;
  }
  final String comicIdToOpen = sortedItems.first.comicId;
  appRouter.pushNamed(
    ReaderRouteArgs.readerRouteName,
    queryParameters: ReaderRouteArgs(
      comicId: comicIdToOpen,
      readType: ReaderRouteArgs.readTypeSeries,
      seriesName: series.name,
    ).toQueryParameters(),
  );
}
