import 'package:flutter/material.dart';
import 'package:hentai_library/shared/ui/layout/page_layout_spec.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/core/l10n/app_localizations.dart';
import 'package:hentai_library/core/l10n/app_localizations_x.dart';
import 'package:hentai_library/shared/ui/catalog/detail/content_breadcrumb_labels.dart';
import 'package:hentai_library/features/library_browse/presentation/browse/models/comic_browse_view_object.dart';
import 'package:hentai_library/features/library_browse/presentation/browse/models/series_browse_view_object.dart';
import 'package:hentai_library/features/series/public/ui/series_cover_content.dart';
import 'package:hentai_library/features/library_browse/presentation/browse/view_models/library_catalog_inactive_subscription.dart';
import 'package:hentai_library/features/library_browse/presentation/browse/view_models/library_catalog_selectors.dart';
import 'package:hentai_library/features/library_browse/presentation/browse/view_models/library_catalog_state.dart';
import 'package:hentai_library/features/library_browse/presentation/browse/view_models/library_comics_catalog_controller.dart';
import 'package:hentai_library/features/library_browse/presentation/browse/view_models/library_page_facade_notifier.dart';
import 'package:hentai_library/shared/domain/catalog/pagination/library_pagination.dart';
import 'package:hentai_library/features/library_browse/presentation/browse/view_models/library_series_catalog_controller.dart';
import 'package:hentai_library/shared/domain/catalog/selection/catalog_selection_notifier.dart';
import 'package:hentai_library/features/library_browse/presentation/browse/views/library/library_filter_sort_sheet.dart';
import 'package:hentai_library/features/library_browse/presentation/browse/views/library/library_overflow_entries.dart';
import 'package:hentai_library/shared/ui/catalog/selection/library_selection_header.dart';
import 'package:hentai_library/features/comic/public/di/comic_cover_providers.dart';
import 'package:hentai_library/features/comic/public/di/comic_detail_providers.dart';
import 'package:hentai_library/features/comic/public/ui/comic_card_actions.dart';
import 'package:hentai_library/features/comic/public/ui/comic_cover_content.dart';
import 'package:hentai_library/features/comic/public/ui/comic_catalog_selection_actions.dart';
import 'package:hentai_library/shared/ui/layout/breakpoints.dart';
import 'package:hentai_library/shared/ui/layout/catalog_grid.dart';
import 'package:hentai_library/shared/ui/layout/catalog_grid_metrics.dart';
import 'package:hentai_library/shared/ui/layout/catalog_list_layout.dart';
import 'package:hentai_library/shared/ui/widgets/actions/catalog_view_mode_button_group.dart';
import 'package:hentai_library/shared/ui/widgets/catalog/comic_list_item.dart';
import 'package:hentai_library/shared/ui/layout/library_browse_page_metrics.dart';
import 'package:hentai_library/shared/ui/layout/spacing.dart';
import 'package:hentai_library/features/library_browse/presentation/browse/patterns/library/library_catalog_toolbar.dart';
import 'package:hentai_library/features/library_browse/presentation/browse/patterns/library/library_page_header.dart';
import 'package:hentai_library/shared/ui/patterns/shared/page_header.dart';
import 'package:hentai_library/shared/ui/motion/mode_chrome_transition.dart';
import 'package:hentai_library/shared/ui/shell/desktop_shell_surfaces.dart';
import 'package:hentai_library/shared/ui/widgets/catalog/comic_card.dart';
import 'package:hentai_library/shared/ui/widgets/navigation/expressive_library_scroll_to_top_button.dart';
import 'package:hentai_library/shared/ui/widgets/pagination/pagination.dart';
import 'package:hentai_library/shared/di/app_router_provider.dart';
import 'package:hentai_library/shared/di/browse_library_scope_providers.dart';
import 'package:hentai_library/shared/di/library_state_providers.dart';
import 'package:hentai_library/shared/domain/models/entity/library/local_library.dart';
import 'package:hentai_library/shared/domain/models/enums.dart';
import 'package:hentai_library/shared/ui/widgets/navigation/library_scroll_to_top_button.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:hentai_library/features/library_admin/public.dart';

/// 库页（MD3E 生产实现）：页头 + 漫画 / 系列 Tab + 真 Sliver 网格 + 分页。
///
/// 双 Tab 以 [IndexedStack] 保活，隐藏侧 [TickerMode] 关闭；目录用
/// [CatalogGridSliver] / [CatalogListSliver] 懒构建，避免 shrinkWrap 整页 layout
/// 与 Peer 过渡双树。
class LibraryPage extends ConsumerStatefulWidget {
  const LibraryPage({super.key});

  @override
  ConsumerState<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends ConsumerState<LibraryPage> {
  final ScrollController _comicsScrollController = ScrollController();
  final ScrollController _seriesScrollController = ScrollController();
  CatalogViewMode _viewMode = CatalogViewMode.grid;

  /// 首帧后再挂非活跃 Tab / 预热其 catalog，避免与活跃 Tab 抢首屏。
  bool _keepAlivePeerTab = false;
  bool _warmInactiveCatalogs = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _keepAlivePeerTab = true;
        _warmInactiveCatalogs = true;
      });
    });
  }

  @override
  void dispose() {
    _comicsScrollController.dispose();
    _seriesScrollController.dispose();
    super.dispose();
  }

  ScrollController _controllerFor(LibraryDisplayTarget target) {
    return switch (target) {
      LibraryDisplayTarget.comics => _comicsScrollController,
      LibraryDisplayTarget.series => _seriesScrollController,
    };
  }

  void _jumpActiveToTop(LibraryDisplayTarget target) {
    final ScrollController controller = _controllerFor(target);
    if (controller.hasClients && controller.offset > 0) {
      controller.jumpTo(0);
    }
  }

  void _scrollActiveToTop(LibraryDisplayTarget target) {
    final ScrollController controller = _controllerFor(target);
    if (!controller.hasClients) {
      return;
    }
    controller.animateTo(
      0,
      duration: kLibraryScrollToTopScrollDuration,
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_warmInactiveCatalogs) {
      ref.watch(libraryCatalogInactiveSubscriptionProvider);
    }

    ref.listen<LibraryPageFacadeState>(libraryPageFacadeProvider, (
      LibraryPageFacadeState? previous,
      LibraryPageFacadeState next,
    ) {
      if (!libraryPageShouldScrollToTop(previous, next)) {
        return;
      }
      final bool displayTargetChanged =
          previous != null && previous.displayTarget != next.displayTarget;
      if (displayTargetChanged) {
        // 漫画↔系列：勿清封面视口（避免进入页首帧 inViewport=false 占位闪一下），
        // 已滚过的列表瞬时回顶。
        _jumpActiveToTop(next.displayTarget);
        return;
      }
      ref
          .read(coverViewportProvider(CoverViewportScopes.library).notifier)
          .clear();
      _scrollActiveToTop(next.displayTarget);
    });

    final bool librarySelection = ref.watch(
      catalogSelectionProvider.select(
        (CatalogSelectionState state) => state.isLibraryBrowseSelection,
      ),
    );
    final LibraryDisplayTarget target = ref.watch(
      libraryPageFacadeProvider.select(
        (LibraryPageFacadeState state) => state.displayTarget,
      ),
    );
    final bool mountComics =
        target == LibraryDisplayTarget.comics || _keepAlivePeerTab;
    final bool mountSeries =
        target == LibraryDisplayTarget.series || _keepAlivePeerTab;

    return PopScope(
      canPop: !librarySelection,
      onPopInvokedWithResult: (bool didPop, Object? result) {
        if (!didPop && librarySelection) {
          ref.read(catalogSelectionProvider.notifier).exit();
        }
      },
      child: Scaffold(
        backgroundColor: labBrowseCanvasColor(M3ETheme.of(context).colorScheme),
        body: Stack(
          children: <Widget>[
            IndexedStack(
              index: target == LibraryDisplayTarget.comics ? 0 : 1,
              children: <Widget>[
                TickerMode(
                  enabled: target == LibraryDisplayTarget.comics,
                  child: mountComics
                      ? _LibraryTabScrollView(
                          scrollController: _comicsScrollController,
                          target: LibraryDisplayTarget.comics,
                          viewMode: _viewMode,
                          warmPeerCounts: _warmInactiveCatalogs,
                          onViewModeChanged: (CatalogViewMode mode) {
                            setState(() => _viewMode = mode);
                          },
                        )
                      : const SizedBox.shrink(),
                ),
                TickerMode(
                  enabled: target == LibraryDisplayTarget.series,
                  child: mountSeries
                      ? _LibraryTabScrollView(
                          scrollController: _seriesScrollController,
                          target: LibraryDisplayTarget.series,
                          viewMode: _viewMode,
                          warmPeerCounts: _warmInactiveCatalogs,
                          onViewModeChanged: (CatalogViewMode mode) {
                            setState(() => _viewMode = mode);
                          },
                        )
                      : const SizedBox.shrink(),
                ),
              ],
            ),
            ExpressiveLibraryScrollToTopButton(
              scrollController: _controllerFor(target),
              horizontalPadding: PageLayoutSpec.of(context).horizontalInset,
            ),
          ],
        ),
      ),
    );
  }
}

/// 单 Tab 完整滚动树：页头 + 工具栏 + 视口模式 + 真 Sliver 目录 + 分页。
class _LibraryTabScrollView extends ConsumerWidget {
  const _LibraryTabScrollView({
    required this.scrollController,
    required this.target,
    required this.viewMode,
    required this.warmPeerCounts,
    required this.onViewModeChanged,
  });

  final ScrollController scrollController;
  final LibraryDisplayTarget target;
  final CatalogViewMode viewMode;
  final bool warmPeerCounts;
  final ValueChanged<CatalogViewMode> onViewModeChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final PageLayoutSpec layout = PageLayoutSpec.of(context);
    final WindowSizeClass sizeClass = layout.sizeClass;
    final double horizontal = layout.horizontalInset;

    return CustomScrollView(
      controller: scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: <Widget>[
        SliverPersistentHeader(
          pinned: true,
          delegate: PageHeaderDelegate(
            layout: layout,
            child: const _LibraryModeHeader(),
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
            child: _LibraryCatalogToolbarSlot(warmPeerCounts: warmPeerCounts),
          ),
        ),
        SliverPadding(
          padding: EdgeInsets.fromLTRB(
            horizontal,
            LibraryBrowsePageMetrics.catalogToolbarToViewModeSpacing(sizeClass),
            horizontal,
            0,
          ),
          sliver: SliverToBoxAdapter(
            child: Align(
              alignment: Alignment.centerRight,
              child: CatalogViewModeButtonGroup(
                mode: viewMode,
                onModeChanged: onViewModeChanged,
              ),
            ),
          ),
        ),
        ..._LibraryCatalogSlivers.build(
          context,
          ref,
          target: target,
          viewMode: viewMode,
          horizontal: horizontal,
          headerToBodyGap: layout.headerToBodyGap,
          bottomInset: LibraryBrowsePageMetrics.scrollBottomInset(sizeClass),
        ),
      ],
    );
  }
}

/// 页头：选择态 / 库名 / 筛选旗标；不订阅阅读进度与网格内容。
class _LibraryModeHeader extends ConsumerWidget {
  const _LibraryModeHeader();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool librarySelection = ref.watch(
      catalogSelectionProvider.select(
        (CatalogSelectionState state) => state.isLibraryBrowseSelection,
      ),
    );

    final Widget modeHeader = librarySelection
        ? LibrarySelectionHeader(
            onEditMetadata:
                (BuildContext context, WidgetRef ref, List<String> ids) =>
                    openComicMetadataEditorForIds(
                      context,
                      ref,
                      ids,
                      exitSelectionOnDone: true,
                    ),
            pageComicIds: ref.watch(
              libraryComicsCatalogControllerProvider.select((
                AsyncValue<LibraryComicsCatalogState> async,
              ) {
                final LibraryComicsCatalogState? catalog =
                    stableCatalogSnapshot(async);
                return <String>[
                  for (final ComicBrowseViewObject item
                      in catalog?.items ?? const <ComicBrowseViewObject>[])
                    item.comicId,
                ];
              }),
            ),
          )
        : const _LibraryBrowsePageHeader();

    return ModeChromeTransition(
      switchKey: librarySelection,
      reverse: !librarySelection,
      child: modeHeader,
    );
  }
}

class _LibraryBrowsePageHeader extends ConsumerWidget {
  const _LibraryBrowsePageHeader();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final LibraryPageFacadeState facade = ref.watch(libraryPageFacadeProvider);
    final LibraryPageFacadeNotifier facadeNotifier = ref.read(
      libraryPageFacadeProvider.notifier,
    );
    final String? browseLibraryId = ref.watch(browseLibraryIdProvider);
    final String? libraryName = ref.watch(
      librariesStateProvider.select((AsyncValue<LibrariesState> async) {
        if (browseLibraryId == null) {
          return null;
        }
        final LibrariesState? state = async.asData?.value;
        final LocalLibrary? library = state?.findById(browseLibraryId);
        return library == null ? null : localLibraryDisplayName(library);
      }),
    );
    final bool scanning = ref.watch(
      libraryScanActivityStateProvider.select(
        (LibraryScanActivityState state) => state.running,
      ),
    );
    final LibraryDisplayTarget target = facade.displayTarget;

    return LibraryPageHeader(
      title: libraryName,
      filterSortActive: facade.isFilterSortCustomized,
      pageSize: target == LibraryDisplayTarget.comics
          ? facade.comicsPageSize
          : facade.seriesPageSize,
      onPageSizeChanged: facadeNotifier.setPageSize,
      onFilterSort: () => LibraryFilterSortSheet.show(context),
      overflowMenuEntries: buildLibraryOverflowEntries(
        context: context,
        ref: ref,
        scanning: scanning,
        showSelectionEntry: target == LibraryDisplayTarget.comics,
      ),
    );
  }
}

/// 工具栏：订阅 Tab 目标；非活跃侧计数可延后到 [warmPeerCounts]。
class _LibraryCatalogToolbarSlot extends ConsumerWidget {
  const _LibraryCatalogToolbarSlot({required this.warmPeerCounts});

  final bool warmPeerCounts;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final LibraryDisplayTarget target = ref.watch(
      libraryPageFacadeProvider.select(
        (LibraryPageFacadeState state) => state.displayTarget,
      ),
    );
    final int comicCount =
        target == LibraryDisplayTarget.comics || warmPeerCounts
        ? ref.watch(libraryDisplayedComicCountProvider)
        : 0;
    final int seriesCount =
        target == LibraryDisplayTarget.series || warmPeerCounts
        ? ref.watch(libraryDisplayedSeriesCountProvider)
        : 0;

    return LibraryCatalogToolbar(
      displayTarget: target,
      comicCount: comicCount,
      seriesCount: seriesCount,
      onDisplayTargetChanged: ref
          .read(libraryPageFacadeProvider.notifier)
          .selectDisplayTarget,
    );
  }
}

/// 目录 + 分页 sliver 工厂（按当前 Tab 目标只构建一侧内容树）。
abstract final class _LibraryCatalogSlivers {
  static List<Widget> build(
    BuildContext context,
    WidgetRef ref, {
    required LibraryDisplayTarget target,
    required CatalogViewMode viewMode,
    required double horizontal,
    required double headerToBodyGap,
    required double bottomInset,
  }) {
    // 各 Tab 只订阅本侧 catalog；非活跃侧由首帧后的 inactive subscription /
    // IndexedStack peer mount 预热，避免首屏双 fetch。
    final LibraryComicsCatalogState? comicsCatalog =
        target == LibraryDisplayTarget.comics
        ? stableCatalogSnapshot(
            ref.watch(libraryComicsCatalogControllerProvider),
          )
        : null;
    final LibrarySeriesCatalogState? seriesCatalog =
        target == LibraryDisplayTarget.series
        ? stableCatalogSnapshot(
            ref.watch(librarySeriesCatalogControllerProvider),
          )
        : null;
    final Map<String, int> readPages = target == LibraryDisplayTarget.comics
        ? (ref.watch(comicReadPageIndexByIdProvider).value ??
              const <String, int>{})
        : const <String, int>{};
    final CatalogSelectionState selection = ref.watch(catalogSelectionProvider);
    final LibraryPagination? pagination = switch (target) {
      LibraryDisplayTarget.comics => comicsCatalog?.pagination,
      LibraryDisplayTarget.series => seriesCatalog?.pagination,
    };

    final List<Widget> catalogSlivers = _catalogBodySlivers(
      context,
      ref,
      target: target,
      comicsCatalog: comicsCatalog,
      seriesCatalog: seriesCatalog,
      selection: selection,
      viewMode: viewMode,
      readPages: readPages,
    );

    return <Widget>[
      SliverPadding(
        padding: EdgeInsets.fromLTRB(
          horizontal,
          headerToBodyGap,
          horizontal,
          0,
        ),
        sliver: catalogSlivers.length == 1
            ? catalogSlivers.first
            : SliverMainAxisGroup(slivers: catalogSlivers),
      ),
      if (pagination != null && pagination.totalPages > 1)
        SliverPadding(
          padding: EdgeInsets.fromLTRB(
            horizontal,
            Spacing.space16,
            horizontal,
            bottomInset,
          ),
          sliver: SliverToBoxAdapter(
            child: Pagination(
              page: pagination.page,
              totalPages: pagination.totalPages,
              totalItems: pagination.totalCount,
              onPageChanged: (int page) {
                ref
                    .read(libraryPageFacadeProvider.notifier)
                    .setPage(target, page);
              },
            ),
          ),
        )
      else
        SliverToBoxAdapter(child: SizedBox(height: bottomInset)),
    ];
  }

  static void _openComicDetail(WidgetRef ref, String comicId) {
    ref.read(comicDetailReturnSeriesProvider.notifier).clear();
    ref
        .read(appRouterProvider)
        .pushNamed(
          ContentBreadcrumbLabels.comicDetail,
          pathParameters: <String, String>{'id': comicId},
        );
  }

  static void _openSeriesDetail(WidgetRef ref, String seriesId) {
    ref
        .read(appRouterProvider)
        .push('/series/${Uri.encodeComponent(seriesId)}');
  }

  static List<Widget> _catalogBodySlivers(
    BuildContext context,
    WidgetRef ref, {
    required LibraryDisplayTarget target,
    required CatalogViewMode viewMode,
    required LibraryComicsCatalogState? comicsCatalog,
    required LibrarySeriesCatalogState? seriesCatalog,
    required CatalogSelectionState selection,
    required Map<String, int> readPages,
  }) {
    final AppLocalizations l10n = context.l10n;
    final bool librarySelection = selection.isLibraryBrowseSelection;
    switch (target) {
      case LibraryDisplayTarget.comics:
        if (comicsCatalog == null) {
          return const <Widget>[_LibraryLoadingSliver()];
        }
        if (comicsCatalog.items.isEmpty) {
          return <Widget>[
            _LibraryEmptySliver(
              title: comicsCatalog.isComicTableEmpty
                  ? l10n.libraryEmptyTitle
                  : l10n.libraryNoMatchTitle,
            ),
          ];
        }
        final List<ComicBrowseViewObject> comics = comicsCatalog.items;
        if (viewMode == CatalogViewMode.list) {
          return <Widget>[
            CatalogListSliver(
              itemCount: comics.length,
              itemBuilder: (BuildContext context, int index) {
                final ComicBrowseViewObject comic = comics[index];
                return ComicCardActions.fromBrowse(
                  item: comic,
                  enabled: !librarySelection,
                  child: ComicListItem(
                    title: comic.title,
                    pageLabel: l10n.comicDetailPageCount(comic.pageCount),
                    cover: ComicCoverContent(
                      comicId: comic.comicId,
                      gridIndex: index,
                      coverViewportScope: CoverViewportScopes.library,
                    ),
                    readProgress: comicReadProgressFor(
                      pageIndex: readPages[comic.comicId],
                      pageCount: comic.pageCount,
                    ),
                    selectionMode: librarySelection,
                    selected: selection.selectedIds.contains(comic.comicId),
                    onTap: () => _openComicDetail(ref, comic.comicId),
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
          CatalogGridSliver(
            horizontalMargin: 0,
            itemCount: comics.length,
            itemBuilder:
                (BuildContext context, int index, CatalogGridLayout _) {
                  final ComicBrowseViewObject comic = comics[index];
                  return ComicCardActions.fromBrowse(
                    key: ValueKey<String>(comic.comicId),
                    item: comic,
                    enabled: !librarySelection,
                    child: ComicCard(
                      title: comic.title,
                      subtitle: l10n.comicDetailPageCount(comic.pageCount),
                      cover: ComicCoverContent(
                        comicId: comic.comicId,
                        gridIndex: index,
                        coverViewportScope: CoverViewportScopes.library,
                      ),
                      readProgress: comicReadProgressFor(
                        pageIndex: readPages[comic.comicId],
                        pageCount: comic.pageCount,
                      ),
                      selectionMode: librarySelection,
                      selected: selection.selectedIds.contains(comic.comicId),
                      onTap: () => _openComicDetail(ref, comic.comicId),
                      onSelectionChanged: (_) => ref
                          .read(catalogSelectionProvider.notifier)
                          .toggle(comic.comicId),
                    ),
                  );
                },
          ),
        ];
      case LibraryDisplayTarget.series:
        if (seriesCatalog == null) {
          return const <Widget>[_LibraryLoadingSliver()];
        }
        if (seriesCatalog.items.isEmpty) {
          return <Widget>[
            _LibraryEmptySliver(
              title: seriesCatalog.isSeriesTableEmpty
                  ? l10n.librarySeriesEmptyTitle
                  : l10n.libraryNoMatchTitle,
            ),
          ];
        }
        final List<SeriesBrowseViewObject> series = seriesCatalog.items;
        if (viewMode == CatalogViewMode.list) {
          return <Widget>[
            CatalogListSliver(
              itemCount: series.length,
              itemBuilder: (BuildContext context, int index) {
                final SeriesBrowseViewObject s = series[index];
                return ComicListItem(
                  title: s.name,
                  pageLabel: context.l10n.seriesVolumeCountLabel(s.volumeCount),
                  cover: SeriesCoverContent(
                    seriesId: s.id,
                    gridIndex: index,
                    coverViewportScope: CoverViewportScopes.library,
                  ),
                  onTap: () => _openSeriesDetail(ref, s.id),
                );
              },
            ),
          ];
        }
        return <Widget>[
          CatalogGridSliver(
            horizontalMargin: 0,
            hasSubtitle: true,
            itemCount: series.length,
            itemBuilder:
                (BuildContext context, int index, CatalogGridLayout _) {
                  final SeriesBrowseViewObject s = series[index];
                  return ComicCard(
                    key: ValueKey<String>('library-series-${s.id}'),
                    title: s.name,
                    subtitle: context.l10n.seriesVolumeCountLabel(
                      s.volumeCount,
                    ),
                    cover: SeriesCoverContent(
                      seriesId: s.id,
                      gridIndex: index,
                      coverViewportScope: CoverViewportScopes.library,
                    ),
                    onTap: () => _openSeriesDetail(ref, s.id),
                  );
                },
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

class _LibraryEmptySliver extends StatelessWidget {
  const _LibraryEmptySliver({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 64),
        child: Center(
          child: Text(
            title,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}
