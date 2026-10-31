import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hentai_library/core/l10n/app_localizations.dart';
import 'package:hentai_library/core/l10n/app_localizations_x.dart';
import 'package:hentai_library/features/library_browse/presentation/content_breadcrumb_labels.dart';
import 'package:hentai_library/features/library_browse/presentation/view_models/comic_detail_return_series_notifier.dart';
import 'package:hentai_library/features/library_browse/presentation/view_models/library_search_page_providers.dart';
import 'package:hentai_library/features/library_browse/presentation/view_models/library_search_query_parser.dart';
import 'package:hentai_library/md3e/layout/md3e_catalog_grid.dart';
import 'package:hentai_library/md3e/layout/md3e_catalog_grid_metrics.dart';
import 'package:hentai_library/md3e/theme/md3e_theme.dart';
import 'package:hentai_library/md3e/widgets/catalog/md3e_comic_card.dart';
import 'package:hentai_library/md3e/widgets/inputs/md3e_outlined_text_field.dart';
import 'package:hentai_library/shared/di/app_router_provider.dart';
import 'package:hentai_library/shared/di/library_management_providers.dart';
import 'package:hentai_library/shared/domain/models/entity/comic/comic.dart';
import 'package:hentai_library/shared/ui/widgets/element/image/comic_cover_content.dart';
import 'package:hentai_library/shared/ui/widgets/feedback/custom_toast.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

const double _kSearchLoadMoreThreshold = 400;
const Duration _kLoadMoreMinInterval = Duration(milliseconds: 400);

/// 搜索结果页（MD3E 生产实现）：页头 + 搜索框 + 漫画网格，触底按页追加。
///
/// 数据沿用 [librarySearchPageComicsControllerProvider]；不得在本页 watch 写库
/// revision 叶子，否则缩略图写库会导致结果区反复重抓（见 searched 闪烁测试）。
class SearchedMd3ePage extends ConsumerStatefulWidget {
  const SearchedMd3ePage({super.key, required this.query});

  final String query;

  @override
  ConsumerState<SearchedMd3ePage> createState() => _SearchedMd3ePageState();
}

class _SearchedMd3ePageState extends ConsumerState<SearchedMd3ePage> {
  late final TextEditingController _searchController = TextEditingController(
    text: widget.query.trim(),
  );
  DateTime? _lastLoadMoreAttemptAt;

  @override
  void didUpdateWidget(covariant SearchedMd3ePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    final String next = widget.query.trim();
    if (oldWidget.query.trim() != next && _searchController.text != next) {
      _searchController.text = next;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
    if (last != null && now.difference(last) < _kLoadMoreMinInterval) {
      return false;
    }
    _lastLoadMoreAttemptAt = now;
    ref
        .read(librarySearchPageComicsControllerProvider(query).notifier)
        .loadMore();
    return false;
  }

  void _submitSearch(String value) {
    final String query = value.trim();
    if (query.isEmpty) {
      showInfoToast(context, context.l10n.librarySearchKeywordEmpty);
      return;
    }
    ref
        .read(appRouterProvider)
        .push('/searched?q=${Uri.encodeQueryComponent(query)}');
  }

  void _openComicDetail(String comicId) {
    ref.read(comicDetailReturnSeriesProvider.notifier).clear();
    ref
        .read(appRouterProvider)
        .pushNamed(
          ContentBreadcrumbLabels.comicDetail,
          pathParameters: <String, String>{'id': comicId},
        );
  }

  @override
  Widget build(BuildContext context) {
    final String trimmedQuery = widget.query.trim();
    final AsyncValue<LibrarySearchComicsPage> searched = ref.watch(
      librarySearchPageComicsControllerProvider(trimmedQuery),
    );
    // Prefer asData so reload frames keep prior items (avoid empty flash).
    final LibrarySearchComicsPage? resolved = searched.asData?.value;
    final List<Comic> comics = resolved?.items ?? const <Comic>[];
    final int resultCount = resolved?.totalCount ?? comics.length;

    // 生产路径无 Md3eThemeScope，补上应用字体（同首页 HomeMd3ePage）。
    return M3ETheme(
      data: md3eWithAppFontFamily(M3ETheme.of(context)),
      child: NotificationListener<ScrollNotification>(
        onNotification: (ScrollNotification notification) =>
            _onScrollNotification(notification, trimmedQuery),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: <Widget>[
            SliverToBoxAdapter(
              child: _SearchedHeader(
                title: trimmedQuery.isEmpty
                    ? context.l10n.searchResultsTitle
                    : unwrapFullyQuotedLibrarySearchQuery(trimmedQuery) ??
                          trimmedQuery,
                resultCount: resultCount,
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: Md3eOutlinedTextField(
                  label: context.l10n.librarySearchHint,
                  controller: _searchController,
                  onSubmitted: _submitSearch,
                  leading: const Icon(Icons.search),
                ),
              ),
            ),
            ..._buildBody(
              context,
              trimmedQuery: trimmedQuery,
              searched: searched,
              comics: comics,
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildBody(
    BuildContext context, {
    required String trimmedQuery,
    required AsyncValue<LibrarySearchComicsPage> searched,
    required List<Comic> comics,
  }) {
    final AppLocalizations l10n = context.l10n;
    if (trimmedQuery.isEmpty) {
      return <Widget>[
        SliverFillRemaining(
          hasScrollBody: false,
          child: Center(child: Text(l10n.searchEnterKeyword)),
        ),
      ];
    }
    if (searched.isLoading && !searched.hasValue) {
      return const <Widget>[
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 48),
            child: Center(child: CircularProgressIndicator()),
          ),
        ),
      ];
    }
    if (searched.hasError && !searched.hasValue) {
      return <Widget>[
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              l10n.searchLoadFailed(searched.error.toString()),
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ),
      ];
    }
    if (comics.isEmpty) {
      return <Widget>[
        SliverToBoxAdapter(
          child: _SearchResultsEmptyState(
            onGoToLibrary: () => goCurrentLibraryBrowseFromContext(context),
          ),
        ),
      ];
    }
    return <Widget>[
      SliverPadding(
        padding: const EdgeInsets.only(bottom: 24),
        sliver: Md3eCatalogGridSliver(
          itemCount: comics.length,
          itemBuilder:
              (BuildContext context, int index, Md3eCatalogGridLayout _) {
                final Comic comic = comics[index];
                return Md3eComicCard(
                  key: Key('search-comic-${comic.comicId}'),
                  title: comic.title,
                  subtitle: l10n.comicDetailPageCount(comic.pageCount),
                  cover: ComicCoverContent(comicId: comic.comicId),
                  onTap: () => _openComicDetail(comic.comicId),
                );
              },
        ),
      ),
    ];
  }
}

class _SearchedHeader extends StatelessWidget {
  const _SearchedHeader({required this.title, required this.resultCount});

  final String title;
  final int resultCount;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 16, 16, 8),
      child: Row(
        children: <Widget>[
          IconButton(
            tooltip: context.l10n.shellBack,
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              if (context.canPop()) {
                context.pop();
                return;
              }
              goCurrentLibraryBrowseFromContext(context);
            },
          ),
          Flexible(
            child: Text(
              title,
              style: theme.textTheme.titleLarge,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '$resultCount',
            key: const Key('searched-result-count'),
            style: theme.textTheme.labelLarge,
          ),
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
    final AppLocalizations l10n = context.l10n;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(
            Icons.search_off,
            size: 40,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 12),
          Text(l10n.libraryNoMatchTitle),
          TextButton.icon(
            onPressed: onGoToLibrary,
            icon: const Icon(Icons.local_library_outlined, size: 16),
            label: Text(l10n.searchBackToLibrary),
          ),
        ],
      ),
    );
  }
}
