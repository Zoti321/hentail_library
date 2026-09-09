import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/core/l10n/app_localizations.dart';
import 'package:hentai_library/core/l10n/app_localizations_x.dart';
import 'package:hentai_library/domain/models/entity/comic/comic.dart';
import 'package:hentai_library/ui/core/theme/theme.dart';
import 'package:hentai_library/ui/core/widgets/element/card/comic_card.dart';
import 'package:hentai_library/ui/features/library/views/library_page/widgets/widgets.dart';
import 'package:hentai_library/ui/features/library/views/searched_page/widgets/searched_page_header.dart';
import 'package:hentai_library/ui/features/shell/views/navigation/library_management_actions.dart';
import 'package:hentai_library/ui/features/shell/views/routing/app_router.dart';
import 'package:hentai_library/ui/providers.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

const double _kSearchLoadMoreThreshold = 400;

/// Kept as [ConsumerStatefulWidget] for pinned-header measure + load-more
/// throttle, matching library/history page shells.
class SearchedPage extends ConsumerStatefulWidget {
  const SearchedPage({super.key, required this.query});

  final String query;

  @override
  ConsumerState<SearchedPage> createState() => _SearchedPageState();
}

class _SearchedPageState extends ConsumerState<SearchedPage> {
  final GlobalKey _headerMeasureKey = GlobalKey();
  double? _headerExtent;
  DateTime? _lastLoadMoreAttemptAt;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    WidgetsBinding.instance.addPostFrameCallback(_measureHeaderExtent);
  }

  void _measureHeaderExtent(Duration _) {
    final RenderBox? box =
        _headerMeasureKey.currentContext?.findRenderObject() as RenderBox?;
    if (!mounted || box == null) {
      return;
    }
    final double height = box.size.height;
    if (_headerExtent != height) {
      setState(() => _headerExtent = height);
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final LibraryLayoutTier layoutTier = libraryLayoutTierForWidth(
          constraints.maxWidth,
        );
        final double horizontalPadding = libraryContentHorizontalPadding(
          layoutTier,
        );
        return _buildScrollView(
          context,
          layoutTier: layoutTier,
          horizontalPadding: horizontalPadding,
        );
      },
    );
  }

  bool _onScrollNotification(ScrollNotification notification, String query) {
    if (notification is! ScrollUpdateNotification) {
      return false;
    }
    final ScrollMetrics metrics = notification.metrics;
    if (metrics.maxScrollExtent <= 0) {
      return false;
    }
    final bool nearBottom =
        metrics.pixels >= metrics.maxScrollExtent - _kSearchLoadMoreThreshold;
    if (!nearBottom) {
      return false;
    }
    final DateTime now = DateTime.now();
    final DateTime? last = _lastLoadMoreAttemptAt;
    if (last != null &&
        now.difference(last) < const Duration(milliseconds: 400)) {
      return false;
    }
    _lastLoadMoreAttemptAt = now;
    ref
        .read(librarySearchPageComicsControllerProvider(query).notifier)
        .loadMore();
    return false;
  }

  Widget _buildScrollView(
    BuildContext context, {
    required LibraryLayoutTier layoutTier,
    required double horizontalPadding,
  }) {
    final AppThemeTokens tokens = context.tokens;
    final ColorScheme cs = Theme.of(context).colorScheme;
    final String trimmedQuery = widget.query.trim();

    final AsyncValue<LibrarySearchComicsPage> searchedComics = ref.watch(
      librarySearchPageComicsControllerProvider(trimmedQuery),
    );

    // Prefer asData so reload/loading frames keep prior items (avoid empty flash).
    final LibrarySearchComicsPage? resolvedPage = searchedComics.asData?.value;
    final List<Comic> comics = resolvedPage?.items ?? const <Comic>[];
    final int searchedComicTotal = resolvedPage?.totalCount ?? comics.length;
    final bool isLoading = searchedComics.isLoading;
    final bool hasResolvedData = searchedComics.hasValue;
    final bool hasError = searchedComics.hasError;
    final Object? error = searchedComics.error;

    final AppLocalizations l10n = context.l10n;
    final Widget headerSection = trimmedQuery.isEmpty
        ? SearchedPageHeaderSection(
            layoutTier: layoutTier,
            horizontalPadding: horizontalPadding,
            query: l10n.searchResultsTitle,
            resultCount: 0,
            showQuotes: false,
          )
        : SearchedPageHeaderSection(
            layoutTier: layoutTier,
            horizontalPadding: horizontalPadding,
            query: trimmedQuery,
            resultCount: searchedComicTotal,
          );
    final Widget header = KeyedSubtree(
      key: _headerMeasureKey,
      child: headerSection,
    );

    return NotificationListener<ScrollNotification>(
      onNotification: (ScrollNotification notification) =>
          _onScrollNotification(notification, trimmedQuery),
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: <Widget>[
          if (_headerExtent == null)
            SliverToBoxAdapter(child: header)
          else
            SliverPersistentHeader(
              pinned: true,
              delegate: LibraryPinnedHeaderDelegate(
                extent: _headerExtent!,
                child: header,
              ),
            ),
          if (trimmedQuery.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(child: Text(l10n.searchEnterKeyword)),
            )
          else ...<Widget>[
            SliverPadding(
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                tokens.layout.contentVerticalPadding +
                    kLibrarySearchToGridSpacing,
                horizontalPadding,
                tokens.spacing.lg,
              ),
              sliver: SliverToBoxAdapter(
                child: LibrarySearchField(initialQuery: trimmedQuery),
              ),
            ),
            if (isLoading && !hasResolvedData)
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    vertical: tokens.spacing.xl * 2,
                  ),
                  child: const Center(child: CircularProgressIndicator()),
                ),
              )
            else if (hasError && !hasResolvedData)
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    horizontalPadding,
                    0,
                    horizontalPadding,
                    tokens.layout.contentVerticalPadding,
                  ),
                  child: Text(
                    l10n.searchLoadFailed(error.toString()),
                    style: TextStyle(
                      fontSize: tokens.text.bodySm,
                      color: cs.error,
                    ),
                  ),
                ),
              )
            else if (comics.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                  child: _SearchResultsEmptyState(
                    onGoToLibrary: () =>
                        LibraryManagementActions.goCurrentLibraryBrowseFromContext(
                          context,
                        ),
                  ),
                ),
              )
            else
              SliverPadding(
                padding: EdgeInsets.fromLTRB(
                  horizontalPadding,
                  0,
                  horizontalPadding,
                  tokens.layout.contentVerticalPadding,
                ),
                sliver: SliverGrid(
                  gridDelegate: libraryGridDelegateForTokens(
                    tokens,
                    layoutTier,
                  ),
                  delegate: SliverChildBuilderDelegate((
                    BuildContext context,
                    int index,
                  ) {
                    final Comic comic = comics[index];
                    return Center(
                      child: ComicCard(
                        key: Key('search-comic-${comic.comicId}'),
                        comic: comic,
                        gridIndex: index,
                        onTap: () {
                          ref
                              .read(comicDetailReturnSeriesProvider.notifier)
                              .clear();
                          appRouter.pushNamed(
                            '漫画详情',
                            pathParameters: <String, String>{
                              'id': comic.comicId,
                            },
                          );
                        },
                      ),
                    );
                  }, childCount: comics.length),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _SearchResultsEmptyState extends StatelessWidget {
  const _SearchResultsEmptyState({required this.onGoToLibrary});

  final VoidCallback onGoToLibrary;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final AppThemeTokens tokens = context.tokens;
    final AppLocalizations l10n = context.l10n;
    return Padding(
      padding: EdgeInsets.symmetric(vertical: tokens.spacing.xl * 2),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: tokens.spacing.md,
          children: <Widget>[
            Icon(LucideIcons.searchX, size: 40, color: cs.hentai.textTertiary),
            Text(
              l10n.libraryNoMatchTitle,
              style: TextStyle(
                fontSize: tokens.text.bodyMd,
                color: cs.hentai.textSecondary,
              ),
            ),
            TextButton.icon(
              onPressed: onGoToLibrary,
              icon: const Icon(LucideIcons.library, size: 16),
              label: Text(l10n.searchBackToLibrary),
            ),
          ],
        ),
      ),
    );
  }
}
