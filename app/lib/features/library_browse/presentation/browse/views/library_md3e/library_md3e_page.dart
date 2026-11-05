import 'package:flutter/material.dart';
import 'package:hentai_library/shared/ui/layout/page_layout_spec.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/core/l10n/app_localizations.dart';
import 'package:hentai_library/core/l10n/app_localizations_x.dart';
import 'package:hentai_library/features/library_browse/presentation/catalog/content_breadcrumb_labels.dart';
import 'package:hentai_library/features/library_browse/presentation/integrations/comic_presentation_bridge.dart';
import 'package:hentai_library/features/library_browse/presentation/browse/view_models/library_catalog_inactive_subscription.dart';
import 'package:hentai_library/features/library_browse/presentation/browse/view_models/library_catalog_selectors.dart';
import 'package:hentai_library/features/library_browse/presentation/browse/view_models/library_catalog_state.dart';
import 'package:hentai_library/features/library_browse/presentation/browse/view_models/library_comics_catalog_controller.dart';
import 'package:hentai_library/features/library_browse/presentation/browse/view_models/library_page_facade_notifier.dart';
import 'package:hentai_library/features/library_browse/presentation/browse/view_models/library_page_snapshot.dart';
import 'package:hentai_library/features/library_browse/presentation/browse/view_models/library_series_catalog_controller.dart';
import 'package:hentai_library/features/library_browse/presentation/catalog/view_models/catalog_selection_notifier.dart';
import 'package:hentai_library/features/library_browse/presentation/browse/views/library_md3e/library_md3e_filter_sort_sheet.dart';
import 'package:hentai_library/features/library_browse/presentation/browse/views/library_md3e/library_md3e_overflow_entries.dart';
import 'package:hentai_library/features/library_browse/presentation/browse/views/library_md3e/library_md3e_selection_header.dart';
import 'package:hentai_library/features/library_browse/presentation/browse/views/widgets/md3e_comic_card_actions.dart';
import 'package:hentai_library/shared/ui/layout/breakpoints.dart';
import 'package:hentai_library/shared/ui/layout/catalog_grid.dart';
import 'package:hentai_library/shared/ui/layout/catalog_list_layout.dart';
import 'package:hentai_library/shared/ui/widgets/actions/catalog_view_mode_button_group.dart';
import 'package:hentai_library/shared/ui/widgets/catalog/comic_list_item.dart';
import 'package:hentai_library/shared/ui/layout/library_browse_page_metrics.dart';
import 'package:hentai_library/shared/ui/layout/spacing.dart';
import 'package:hentai_library/features/library_browse/presentation/browse/patterns/library/library_catalog_toolbar.dart';
import 'package:hentai_library/features/library_browse/presentation/browse/patterns/library/library_page_header.dart';
import 'package:hentai_library/shared/ui/patterns/shared/md3e_page_header.dart';
import 'package:hentai_library/shared/ui/shell/desktop_shell_surfaces.dart';
import 'package:hentai_library/shared/ui/widgets/catalog/comic_card.dart';
import 'package:hentai_library/shared/ui/widgets/navigation/expressive_library_scroll_to_top_button.dart';
import 'package:hentai_library/shared/ui/widgets/pagination/pagination.dart';
import 'package:hentai_library/shared/di/app_router_provider.dart';
import 'package:hentai_library/shared/di/browse_library_scope_providers.dart';
import 'package:hentai_library/shared/di/library_state_providers.dart';
import 'package:hentai_library/shared/domain/models/entity/comic/comic.dart';
import 'package:hentai_library/shared/domain/models/entity/comic/series.dart';
import 'package:hentai_library/shared/domain/models/entity/library/local_library.dart';
import 'package:hentai_library/shared/domain/models/enums.dart';
import 'package:hentai_library/shared/ui/widgets/navigation/library_scroll_to_top_button.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:hentai_library/features/library_admin/public.dart';
import 'package:hentai_library/features/library_browse/presentation/integrations/series_presentation_bridge.dart';

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
    final LibraryComicsCatalogState? comicsCatalog = stableCatalogSnapshot(
      ref.watch(libraryComicsCatalogControllerProvider),
    );
    final LibrarySeriesCatalogState? seriesCatalog = stableCatalogSnapshot(
      ref.watch(librarySeriesCatalogControllerProvider),
    );
    final String? browseLibraryId = ref.watch(browseLibraryIdProvider);
    final LibrariesState? librariesState =
        ref.watch(librariesStateProvider).asData?.value;
    final LocalLibrary? browseLibrary = browseLibraryId == null
        ? null
        : librariesState?.findById(browseLibraryId);
    final String? libraryName = browseLibrary == null
        ? null
        : localLibraryDisplayName(browseLibrary);
    final CatalogSelectionState selection = ref.watch(catalogSelectionProvider);
    final bool scanning = ref.watch(
      libraryScanActivityStateProvider.select(
        (LibraryScanActivityState state) => state.running,
      ),
    );
    final Md3ePageLayoutSpec layout = Md3ePageLayoutSpec.of(context);
    final Md3eWindowSizeClass sizeClass = layout.sizeClass;
    final double horizontal = layout.horizontalInset;
    final LibraryDisplayTarget target = facade.displayTarget;
    final LibraryPagination? pagination = switch (target) {
      LibraryDisplayTarget.comics => comicsCatalog?.pagination,
      LibraryDisplayTarget.series => seriesCatalog?.pagination,
    };

    final Widget modeHeader = selection.active
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

    final Widget header = AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (Widget child, Animation<double> animation) {
        final Animation<Offset> slide = Tween<Offset>(
          begin: const Offset(0, -0.12),
          end: Offset.zero,
        ).animate(animation);
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(position: slide, child: child),
        );
      },
      child: KeyedSubtree(
        key: ValueKey<bool>(selection.active),
        child: modeHeader,
      ),
    );

    return PopScope(
      canPop: !selection.active,
      onPopInvokedWithResult: (bool didPop, Object? result) {
        if (!didPop && selection.active) {
          ref.read(catalogSelectionProvider.notifier).exit();
        }
      },
      child: Scaffold(
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
                    layout: layout,
                    child: header,
                  ),
                ),
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(
                    horizontal,
                    layout.headerToBodyGap,
                    horizontal,
                    0,
                  ),
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
                  padding: EdgeInsets.fromLTRB(
                    horizontal,
                    Md3eLibraryBrowsePageMetrics.catalogToolbarToViewModeSpacing(
                      sizeClass,
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
                      Md3eSpacing.space16,
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
      ),
    );
  }

  /// 列表模式：列数由窗口尺寸与平台决定（见 [md3eComicListColumnCount]），与 Widgetbook Lab 一致。
  Widget _buildCatalogListSliver(
    BuildContext context, {
    required double horizontal,
    required int itemCount,
    required Widget Function(BuildContext context, int index) itemBuilder,
  }) {
    final Md3ePageLayoutSpec layout = Md3ePageLayoutSpec.of(context);
    final int columns = md3eComicListColumnCount(layout.sizeClass);
    return SliverPadding(
      padding: EdgeInsets.fromLTRB(
        horizontal,
        layout.headerToBodyGap,
        horizontal,
        0,
      ),
      sliver: columns == 1
          ? SliverList(
              delegate: SliverChildBuilderDelegate(
                (BuildContext context, int index) => Padding(
                  padding: EdgeInsets.only(bottom: layout.listItemGap),
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
                final int firstIndex = rowIndex * columns;
                return Padding(
                  padding: EdgeInsets.only(bottom: layout.listItemGap),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      for (
                        int column = 0;
                        column < columns;
                        column++
                      ) ...<Widget>[
                        if (column > 0) SizedBox(width: layout.listItemGap),
                        Expanded(
                          child: firstIndex + column < itemCount
                              ? itemBuilder(context, firstIndex + column)
                              : const SizedBox.shrink(),
                        ),
                      ],
                    ],
                  ),
                );
              }, childCount: (itemCount + columns - 1) ~/ columns),
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
    final Md3ePageLayoutSpec layout = Md3ePageLayoutSpec.of(context);
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
        final Map<String, int> readPages =
            ref.watch(comicReadPageIndexByIdProvider).value ??
            const <String, int>{};
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
                    readProgress: comicReadProgressFor(
                      pageIndex: readPages[comic.comicId],
                      pageCount: comic.pageCount,
                    ),
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
              layout.headerToBodyGap,
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
                    readProgress: comicReadProgressFor(
                      pageIndex: readPages[comic.comicId],
                      pageCount: comic.pageCount,
                    ),
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
              layout.headerToBodyGap,
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
