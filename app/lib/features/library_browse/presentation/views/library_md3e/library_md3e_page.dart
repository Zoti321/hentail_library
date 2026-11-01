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
import 'package:hentai_library/features/library_browse/presentation/view_models/catalog_selection_notifier.dart';
import 'package:hentai_library/features/library_browse/presentation/views/library_md3e/library_md3e_filter_sort_sheet.dart';
import 'package:hentai_library/features/library_browse/presentation/views/library_md3e/library_md3e_overflow_entries.dart';
import 'package:hentai_library/features/library_browse/presentation/views/library_md3e/library_md3e_selection_header.dart';
import 'package:hentai_library/features/library_browse/presentation/views/widgets/md3e_comic_card_actions.dart';
import 'package:hentai_library/shared/ui/layout/breakpoints.dart';
import 'package:hentai_library/shared/ui/layout/catalog_grid.dart';
import 'package:hentai_library/shared/ui/layout/catalog_list_layout.dart';
import 'package:hentai_library/shared/ui/widgets/actions/catalog_view_mode_button_group.dart';
import 'package:hentai_library/shared/ui/widgets/catalog/comic_list_item.dart';
import 'package:hentai_library/shared/ui/layout/library_browse_page_metrics.dart';
import 'package:hentai_library/features/library_browse/presentation/patterns/library/library_catalog_toolbar.dart';
import 'package:hentai_library/features/library_browse/presentation/patterns/library/library_page_header.dart';
import 'package:hentai_library/shared/ui/patterns/shared/md3e_page_header.dart';
import 'package:hentai_library/shared/ui/shell/desktop_shell_surfaces.dart';
import 'package:hentai_library/shared/ui/widgets/catalog/comic_card.dart';
import 'package:hentai_library/shared/ui/widgets/navigation/expressive_library_scroll_to_top_button.dart';
import 'package:hentai_library/shared/ui/widgets/pagination/pagination.dart';
import 'package:hentai_library/shared/di/app_router_provider.dart';
import 'package:hentai_library/shared/di/library_state_providers.dart';
import 'package:hentai_library/shared/domain/library/current_library_state.dart';
import 'package:hentai_library/shared/domain/library/library_scan_activity_state.dart';
import 'package:hentai_library/shared/domain/models/entity/comic/comic.dart';
import 'package:hentai_library/shared/domain/models/entity/comic/series.dart';
import 'package:hentai_library/shared/domain/models/entity/library/local_library.dart';
import 'package:hentai_library/shared/domain/models/enums.dart';
import 'package:hentai_library/shared/ui/widgets/element/image/comic_cover_content.dart';
import 'package:hentai_library/shared/ui/widgets/element/image/series_cover_content.dart';
import 'package:hentai_library/shared/ui/widgets/navigation/library_scroll_to_top_button.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

/// 工具栏与网格之间的顶部间距。
const double _gridTopGap = 24;

/// 列表行之间（及双列之间）的间距。
const double _listItemGap = 8;

/// 库页（MD3E 生产实现）：页头 + 漫画 / 系列 Tab + 网格 + 分页。
///
/// 数据来自库目录控制器（真实 provider）。筛选排序面板为 [Md3eLibraryFilterSortSheet]。
class LibraryMd3ePage extends ConsumerStatefulWidget {
  const LibraryMd3ePage({super.key});

  @override
  ConsumerState<LibraryMd3ePage> createState() => _LibraryMd3ePageState();
}

class _LibraryMd3ePageState extends ConsumerState<LibraryMd3ePage> {
  final ScrollController _scrollController = ScrollController();
  Md3eCatalogViewMode _viewMode = Md3eCatalogViewMode.grid;

  @override
  void dispose() {
    _scrollController.dispose();
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

  void _openFilterSortSheet() {
    Md3eLibraryFilterSortSheet.show(context);
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
    final CatalogSelectionState selection = ref.watch(catalogSelectionProvider);
    final bool scanning = ref.watch(
      libraryScanActivityStateProvider.select(
        (LibraryScanActivityState state) => state.running,
      ),
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

    final Widget header = selection.active
        ? Md3eLibrarySelectionHeader(
            pageComicIds: <String>[
              for (final Comic comic in comicsCatalog?.items ?? const <Comic>[])
                comic.comicId,
            ],
          )
        : Md3eLibraryPageHeader(
            title: libraryName,
            filterSortActive: facade.isFilterSortCustomized,
            pageSize: target == LibraryDisplayTarget.comics
                ? facade.comicsPageSize
                : facade.seriesPageSize,
            onPageSizeChanged: (int size) {
              facadeNotifier.setPageSize(size);
            },
            onFilterSort: _openFilterSortSheet,
            overflowMenuEntries: buildLibraryMd3eOverflowEntries(
              context: context,
              ref: ref,
              scanning: scanning,
              showSelectionEntry: target == LibraryDisplayTarget.comics,
            ),
          );

    return Scaffold(
      backgroundColor: md3eLabBrowseCanvasColor(
        M3ETheme.of(context).colorScheme,
      ),
      body: Stack(
        children: <Widget>[
          CustomScrollView(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: <Widget>[
              SliverPersistentHeader(
                pinned: true,
                delegate: Md3ePageHeaderDelegate(
                  pageHorizontal: horizontal,
                  child: header,
                ),
              ),
              SliverPadding(
                padding: EdgeInsets.fromLTRB(horizontal, 16, horizontal, 0),
                sliver: SliverToBoxAdapter(
                  child: Md3eLibraryCatalogToolbar(
                    displayTarget: target,
                    comicCount: comicsCatalog?.pagination.totalCount ?? 0,
                    seriesCount: seriesCatalog?.pagination.totalCount ?? 0,
                    onDisplayTargetChanged: facadeNotifier.selectDisplayTarget,
                  ),
                ),
              ),
              SliverPadding(
                padding: EdgeInsets.fromLTRB(
                  horizontal,
                  Md3eLibraryBrowsePageMetrics.catalogToolbarToViewModeSpacing(
                    Md3eWindowSizeClass.fromWidth(
                      MediaQuery.sizeOf(context).width,
                    ),
                  ),
                  horizontal,
                  0,
                ),
                sliver: SliverToBoxAdapter(
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Md3eCatalogViewModeButtonGroup(
                      mode: _viewMode,
                      onModeChanged: (Md3eCatalogViewMode mode) {
                        setState(() => _viewMode = mode);
                      },
                    ),
                  ),
                ),
              ),
              ..._buildCatalog(
                context,
                target: target,
                horizontal: horizontal,
                comicsCatalog: comicsCatalog,
                seriesCatalog: seriesCatalog,
                selection: selection,
                viewMode: _viewMode,
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
          ),
        ],
      ),
    );
  }

  /// 列表模式：单列（compact / medium）或双列（expanded 及以上），与 Widgetbook Lab 一致。
  Widget _buildCatalogListSliver(
    BuildContext context, {
    required double horizontal,
    required int itemCount,
    required Widget Function(BuildContext context, int index) itemBuilder,
  }) {
    final int columns = md3eComicListColumnCount(
      Md3eWindowSizeClass.fromWidth(MediaQuery.sizeOf(context).width),
    );
    return SliverPadding(
      padding: EdgeInsets.fromLTRB(horizontal, _gridTopGap, horizontal, 0),
      sliver: columns == 1
          ? SliverList(
              delegate: SliverChildBuilderDelegate(
                (BuildContext context, int index) => Padding(
                  padding: const EdgeInsets.only(bottom: _listItemGap),
                  child: itemBuilder(context, index),
                ),
                childCount: itemCount,
              ),
            )
          : SliverList(
              delegate: SliverChildBuilderDelegate((
                BuildContext context,
                int rowIndex,
              ) {
                final int leftIndex = rowIndex * 2;
                final int rightIndex = leftIndex + 1;
                return Padding(
                  padding: const EdgeInsets.only(bottom: _listItemGap),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Expanded(child: itemBuilder(context, leftIndex)),
                      const SizedBox(width: _listItemGap),
                      Expanded(
                        child: rightIndex < itemCount
                            ? itemBuilder(context, rightIndex)
                            : const SizedBox.shrink(),
                      ),
                    ],
                  ),
                );
              }, childCount: (itemCount + 1) ~/ 2),
            ),
    );
  }

  List<Widget> _buildCatalog(
    BuildContext context, {
    required LibraryDisplayTarget target,
    required double horizontal,
    required Md3eCatalogViewMode viewMode,
    required LibraryComicsCatalogState? comicsCatalog,
    required LibrarySeriesCatalogState? seriesCatalog,
    required CatalogSelectionState selection,
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
        if (viewMode == Md3eCatalogViewMode.list) {
          return <Widget>[
            _buildCatalogListSliver(
              context,
              horizontal: horizontal,
              itemCount: comics.length,
              itemBuilder: (BuildContext context, int index) {
                final Comic comic = comics[index];
                return Md3eComicCardActions(
                  comic: comic,
                  enabled: !selection.active,
                  child: Md3eComicListItem(
                    title: comic.title,
                    pageLabel: l10n.comicDetailPageCount(comic.pageCount),
                    cover: ComicCoverContent(comicId: comic.comicId),
                    selectionMode: selection.active,
                    selected: selection.selectedIds.contains(comic.comicId),
                    onTap: () => _openComicDetail(comic.comicId),
                    onSelectionChanged: (_) => ref
                        .read(catalogSelectionProvider.notifier)
                        .toggle(comic.comicId),
                  ),
                );
              },
            ),
          ];
        }
        return <Widget>[
          SliverPadding(
            padding: EdgeInsets.fromLTRB(
              horizontal,
              _gridTopGap,
              horizontal,
              0,
            ),
            sliver: Md3eCatalogGridSliver(
              itemCount: comics.length,
              itemBuilder: (BuildContext context, int index, _) {
                final Comic comic = comics[index];
                return Md3eComicCardActions(
                  key: ValueKey<String>(comic.comicId),
                  comic: comic,
                  enabled: !selection.active,
                  child: Md3eComicCard(
                    title: comic.title,
                    subtitle: l10n.comicDetailPageCount(comic.pageCount),
                    cover: ComicCoverContent(comicId: comic.comicId),
                    selectionMode: selection.active,
                    selected: selection.selectedIds.contains(comic.comicId),
                    onTap: () => _openComicDetail(comic.comicId),
                    onSelectionChanged: (_) => ref
                        .read(catalogSelectionProvider.notifier)
                        .toggle(comic.comicId),
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
        if (viewMode == Md3eCatalogViewMode.list) {
          return <Widget>[
            _buildCatalogListSliver(
              context,
              horizontal: horizontal,
              itemCount: series.length,
              itemBuilder: (BuildContext context, int index) {
                final Series s = series[index];
                return Md3eComicListItem(
                  title: s.name,
                  pageLabel: context.l10n.seriesVolumeCountLabel(
                    s.items.length,
                  ),
                  cover: SeriesCoverContent(seriesId: s.id),
                  onTap: () => _openSeriesDetail(s.id),
                );
              },
            ),
          ];
        }
        return <Widget>[
          SliverPadding(
            padding: EdgeInsets.fromLTRB(
              horizontal,
              _gridTopGap,
              horizontal,
              0,
            ),
            sliver: Md3eCatalogGridSliver(
              hasSubtitle: true,
              itemCount: series.length,
              itemBuilder: (BuildContext context, int index, _) {
                final Series s = series[index];
                return Md3eComicCard(
                  key: ValueKey<String>('library-series-${s.id}'),
                  title: s.name,
                  subtitle: context.l10n.seriesVolumeCountLabel(s.items.length),
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
