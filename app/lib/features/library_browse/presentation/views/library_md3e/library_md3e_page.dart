import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/core/l10n/app_localizations.dart';
import 'package:hentai_library/core/l10n/app_localizations_x.dart';
import 'package:hentai_library/features/library_browse/presentation/content_breadcrumb_labels.dart';
import 'package:hentai_library/features/library_browse/presentation/view_models/comic_detail_return_series_notifier.dart';
import 'package:hentai_library/features/library_browse/presentation/view_models/library_catalog_inactive_subscription.dart';
import 'package:hentai_library/features/library_browse/presentation/view_models/library_catalog_state.dart';
import 'package:hentai_library/features/library_browse/presentation/view_models/library_comics_catalog_controller.dart';
import 'package:hentai_library/features/library_browse/presentation/view_models/library_page_facade_notifier.dart';
import 'package:hentai_library/features/library_browse/presentation/view_models/library_page_snapshot.dart';
import 'package:hentai_library/features/library_browse/presentation/view_models/library_series_catalog_controller.dart';
import 'package:hentai_library/features/library_browse/presentation/views/library_page/widgets/library_filter_sort_drawer.dart';
import 'package:hentai_library/features/library_browse/presentation/views/widgets/md3e_comic_card_actions.dart';
import 'package:hentai_library/md3e/layout/md3e_breakpoints.dart';
import 'package:hentai_library/md3e/layout/md3e_catalog_grid.dart';
import 'package:hentai_library/md3e/layout/md3e_library_browse_page_metrics.dart';
import 'package:hentai_library/md3e/patterns/library/md3e_library_catalog_toolbar.dart';
import 'package:hentai_library/md3e/patterns/library/md3e_library_page_header.dart';
import 'package:hentai_library/md3e/theme/md3e_theme.dart';
import 'package:hentai_library/md3e/widgets/catalog/md3e_comic_card.dart';
import 'package:hentai_library/md3e/widgets/inputs/md3e_outlined_text_field.dart';
import 'package:hentai_library/md3e/widgets/navigation/md3e_library_scroll_to_top_button.dart';
import 'package:hentai_library/md3e/widgets/pagination/md3e_pagination.dart';
import 'package:hentai_library/shared/di/app_router_provider.dart';
import 'package:hentai_library/shared/di/library_state_providers.dart';
import 'package:hentai_library/shared/domain/library/current_library_state.dart';
import 'package:hentai_library/shared/domain/models/entity/comic/comic.dart';
import 'package:hentai_library/shared/domain/models/entity/comic/series.dart';
import 'package:hentai_library/shared/domain/models/entity/library/local_library.dart';
import 'package:hentai_library/shared/domain/models/enums.dart';
import 'package:hentai_library/shared/ui/widgets/element/image/comic_cover_content.dart';
import 'package:hentai_library/shared/ui/widgets/element/image/series_cover_content.dart';
import 'package:hentai_library/shared/ui/widgets/navigation/library_scroll_to_top_button.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

/// 库页（MD3E 生产实现）：页头 + 漫画 / 系列 Tab + 搜索入口 + 网格 + 分页。
///
/// 数据来自库目录控制器（真实 provider）。筛选排序抽屉暂复用 Baseline
/// [LibraryFilterSortDrawer]，待抽屉迁移后再删除。
class LibraryMd3ePage extends ConsumerStatefulWidget {
  const LibraryMd3ePage({super.key});

  @override
  ConsumerState<LibraryMd3ePage> createState() => _LibraryMd3ePageState();
}

class _LibraryMd3ePageState extends ConsumerState<LibraryMd3ePage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  bool _isEndDrawerOpen = false;

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _scrollToContentTop() {
    if (!_scrollController.hasClients) {
      return;
    }
    _scrollController.animateTo(
      0,
      duration: kLibraryScrollToTopScrollDuration,
      curve: Curves.easeOutCubic,
    );
  }

  void _openFilterSortDrawer() {
    _scaffoldKey.currentState?.openEndDrawer();
  }

  void _submitSearch(String value) {
    final String query = value.trim();
    if (query.isEmpty) {
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

  void _openSeriesDetail(String seriesId) {
    ref
        .read(appRouterProvider)
        .push('/series/${Uri.encodeComponent(seriesId)}');
  }

  @override
  Widget build(BuildContext context) {
    // 保持非当前 Tab 的目录预热（与 Baseline 库页一致）。
    ref.watch(libraryCatalogInactiveSubscriptionProvider);
    ref.listen<LibraryPageFacadeState>(libraryPageFacadeProvider, (
      LibraryPageFacadeState? previous,
      LibraryPageFacadeState next,
    ) {
      if (!libraryPageShouldScrollToTop(previous, next)) {
        return;
      }
      _scrollToContentTop();
      if (_isEndDrawerOpen && previous?.displayTarget != next.displayTarget) {
        _scaffoldKey.currentState?.closeEndDrawer();
      }
    });

    final LibraryPageFacadeState facade = ref.watch(libraryPageFacadeProvider);
    final LibraryPageFacadeNotifier facadeNotifier = ref.read(
      libraryPageFacadeProvider.notifier,
    );
    final LibraryComicsCatalogState? comicsCatalog = ref
        .watch(libraryComicsCatalogControllerProvider)
        .asData
        ?.value;
    final LibrarySeriesCatalogState? seriesCatalog = ref
        .watch(librarySeriesCatalogControllerProvider)
        .asData
        ?.value;
    final String? libraryName = ref.watch(
      currentLibraryStateProvider.select(_currentLibraryDisplayName),
    );
    final Md3eWindowSizeClass sizeClass = Md3eWindowSizeClass.fromWidth(
      MediaQuery.sizeOf(context).width,
    );
    final double horizontal =
        Md3eLibraryBrowsePageMetrics.contentHorizontalPadding(sizeClass);
    final LibraryDisplayTarget target = facade.displayTarget;
    final LibraryPagination? pagination = switch (target) {
      LibraryDisplayTarget.comics => comicsCatalog?.pagination,
      LibraryDisplayTarget.series => seriesCatalog?.pagination,
    };

    // 生产路径无 Md3eThemeScope，补上应用字体（同首页 HomeMd3ePage）。
    return M3ETheme(
      data: md3eWithAppFontFamily(M3ETheme.of(context)),
      child: Scaffold(
        key: _scaffoldKey,
        endDrawer: const LibraryFilterSortDrawer(),
        onEndDrawerChanged: (bool isOpen) {
          if (_isEndDrawerOpen != isOpen) {
            setState(() => _isEndDrawerOpen = isOpen);
          }
        },
        body: Stack(
          children: <Widget>[
            CustomScrollView(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: <Widget>[
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(horizontal, 16, horizontal, 0),
                  sliver: SliverToBoxAdapter(
                    child: Md3eLibraryPageHeader(
                      title: libraryName,
                      filterSortActive: facade.isFilterSortCustomized,
                      pageSize: target == LibraryDisplayTarget.comics
                          ? facade.comicsPageSize
                          : facade.seriesPageSize,
                      onPageSizeChanged: (int size) {
                        facadeNotifier.setPageSize(size);
                      },
                      onFilterSort: _openFilterSortDrawer,
                    ),
                  ),
                ),
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(horizontal, 16, horizontal, 0),
                  sliver: SliverToBoxAdapter(
                    child: Md3eLibraryCatalogToolbar(
                      displayTarget: target,
                      comicCount: comicsCatalog?.pagination.totalCount ?? 0,
                      seriesCount: seriesCatalog?.pagination.totalCount ?? 0,
                      onDisplayTargetChanged:
                          facadeNotifier.selectDisplayTarget,
                    ),
                  ),
                ),
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(horizontal, 12, horizontal, 0),
                  sliver: SliverToBoxAdapter(
                    child: Md3eOutlinedTextField(
                      label: context.l10n.librarySearchHint,
                      controller: _searchController,
                      onSubmitted: _submitSearch,
                      leading: const Icon(Icons.search),
                    ),
                  ),
                ),
                ..._buildCatalog(
                  context,
                  target: target,
                  horizontal: horizontal,
                  comicsCatalog: comicsCatalog,
                  seriesCatalog: seriesCatalog,
                ),
                if (pagination != null && pagination.totalPages > 1)
                  SliverPadding(
                    padding: EdgeInsets.fromLTRB(
                      horizontal,
                      16,
                      horizontal,
                      Md3eLibraryBrowsePageMetrics.scrollBottomInset(sizeClass),
                    ),
                    sliver: SliverToBoxAdapter(
                      child: Md3ePagination(
                        page: pagination.page,
                        totalPages: pagination.totalPages,
                        totalItems: pagination.totalCount,
                        onPageChanged: (int page) {
                          facadeNotifier.setPage(target, page);
                        },
                      ),
                    ),
                  ),
              ],
            ),
            Md3eLibraryScrollToTopButton(
              scrollController: _scrollController,
              horizontalPadding: horizontal,
              hidden: _isEndDrawerOpen,
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildCatalog(
    BuildContext context, {
    required LibraryDisplayTarget target,
    required double horizontal,
    required LibraryComicsCatalogState? comicsCatalog,
    required LibrarySeriesCatalogState? seriesCatalog,
  }) {
    final AppLocalizations l10n = context.l10n;
    switch (target) {
      case LibraryDisplayTarget.comics:
        if (comicsCatalog == null) {
          return const <Widget>[_LibraryLoadingSliver()];
        }
        if (comicsCatalog.items.isEmpty) {
          return <Widget>[
            SliverToBoxAdapter(
              child: _LibraryEmptyState(
                title: comicsCatalog.isComicTableEmpty
                    ? l10n.libraryEmptyTitle
                    : l10n.libraryNoMatchTitle,
              ),
            ),
          ];
        }
        final List<Comic> comics = comicsCatalog.items;
        return <Widget>[
          SliverPadding(
            padding: EdgeInsets.symmetric(horizontal: horizontal),
            sliver: Md3eCatalogGridSliver(
              itemCount: comics.length,
              itemBuilder: (BuildContext context, int index, _) {
                final Comic comic = comics[index];
                return Md3eComicCardActions(
                  key: ValueKey<String>(comic.comicId),
                  comic: comic,
                  child: Md3eComicCard(
                    title: comic.title,
                    subtitle: l10n.comicDetailPageCount(comic.pageCount),
                    cover: ComicCoverContent(comicId: comic.comicId),
                    onTap: () => _openComicDetail(comic.comicId),
                  ),
                );
              },
            ),
          ),
        ];
      case LibraryDisplayTarget.series:
        if (seriesCatalog == null) {
          return const <Widget>[_LibraryLoadingSliver()];
        }
        if (seriesCatalog.items.isEmpty) {
          return <Widget>[
            SliverToBoxAdapter(
              child: _LibraryEmptyState(
                title: seriesCatalog.isSeriesTableEmpty
                    ? l10n.librarySeriesEmptyTitle
                    : l10n.libraryNoMatchTitle,
              ),
            ),
          ];
        }
        final List<Series> series = seriesCatalog.items;
        return <Widget>[
          SliverPadding(
            padding: EdgeInsets.symmetric(horizontal: horizontal),
            sliver: Md3eCatalogGridSliver(
              hasSubtitle: false,
              itemCount: series.length,
              itemBuilder: (BuildContext context, int index, _) {
                final Series s = series[index];
                return Md3eComicCard(
                  key: ValueKey<String>('library-series-${s.id}'),
                  title: s.name,
                  cover: SeriesCoverContent(seriesId: s.id),
                  onTap: () => _openSeriesDetail(s.id),
                );
              },
            ),
          ),
        ];
    }
  }
}

/// 当前库显示名；无当前库时为 null（页头退回默认标题）。
String? _currentLibraryDisplayName(AsyncValue<CurrentLibraryState> async) {
  final CurrentLibraryState? state = async.asData?.value;
  if (state == null) {
    return null;
  }
  for (final LocalLibrary library in state.libraries) {
    if (library.libraryId == state.currentId) {
      return localLibraryDisplayName(library);
    }
  }
  return null;
}

class _LibraryLoadingSliver extends StatelessWidget {
  const _LibraryLoadingSliver();

  @override
  Widget build(BuildContext context) {
    return const SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 48),
        child: Center(child: CircularProgressIndicator()),
      ),
    );
  }
}

class _LibraryEmptyState extends StatelessWidget {
  const _LibraryEmptyState({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 64),
      child: Center(
        child: Text(
          title,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}
