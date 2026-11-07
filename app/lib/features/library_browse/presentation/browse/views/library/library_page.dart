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
import 'package:hentai_library/features/library_browse/presentation/browse/views/library/library_filter_sort_sheet.dart';
import 'package:hentai_library/features/library_browse/presentation/browse/views/library/library_overflow_entries.dart';
import 'package:hentai_library/features/library_browse/presentation/browse/views/library/library_selection_header.dart';
import 'package:hentai_library/features/library_browse/presentation/browse/views/widgets/comic_card_actions.dart';
import 'package:hentai_library/shared/ui/layout/breakpoints.dart';
import 'package:hentai_library/shared/ui/layout/catalog_grid.dart';
import 'package:hentai_library/shared/ui/layout/catalog_list_layout.dart';
import 'package:hentai_library/shared/ui/widgets/actions/catalog_view_mode_button_group.dart';
import 'package:hentai_library/shared/ui/widgets/catalog/comic_list_item.dart';
import 'package:hentai_library/shared/ui/layout/library_browse_page_metrics.dart';
import 'package:hentai_library/shared/ui/layout/spacing.dart';
import 'package:hentai_library/features/library_browse/presentation/browse/patterns/library/library_catalog_toolbar.dart';
import 'package:hentai_library/features/library_browse/presentation/browse/patterns/library/library_page_header.dart';
import 'package:hentai_library/shared/ui/patterns/shared/page_header.dart';
import 'package:hentai_library/shared/ui/motion/mode_chrome_transition.dart';
import 'package:hentai_library/shared/ui/motion/peer_content_transition.dart';
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
/// 根节点只保留 Facade 滚动监听、选择态布尔与本地 viewMode；
/// 页头 / 工具栏 / 目录+分页各自下沉为独立 Consumer，避免勾选与阅读进度带动整页重建。
class LibraryPage extends ConsumerStatefulWidget {
  const LibraryPage({super.key});

  @override
  ConsumerState<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends ConsumerState<LibraryPage> {
  final ScrollController _scrollController = ScrollController();
  CatalogViewMode _viewMode = CatalogViewMode.grid;

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
      // 漫画↔系列：勿清封面视口（避免进入页首帧 inViewport=false 占位闪一下），
      // 已滚过的列表瞬时回顶，不与 Peer 淡入叠一段 300ms 滚动。
      final bool displayTargetChanged =
          previous != null && previous.displayTarget != next.displayTarget;
      if (displayTargetChanged) {
        if (_scrollController.hasClients && _scrollController.offset > 0) {
          _scrollController.jumpTo(0);
        }
        return;
      }
      ref
          .read(coverViewportProvider(CoverViewportScopes.library).notifier)
          .clear();
      _scrollToContentTop();
    });

    final bool librarySelection = ref.watch(
      catalogSelectionProvider.select(
        (CatalogSelectionState state) => state.isLibraryBrowseSelection,
      ),
    );
    final PageLayoutSpec layout = PageLayoutSpec.of(context);
    final WindowSizeClass sizeClass = layout.sizeClass;
    final double horizontal = layout.horizontalInset;

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
            CustomScrollView(
              controller: _scrollController,
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
                  sliver: const SliverToBoxAdapter(
                    child: _LibraryCatalogToolbarSlot(),
                  ),
                ),
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(
                    horizontal,
                    LibraryBrowsePageMetrics.catalogToolbarToViewModeSpacing(
                      sizeClass,
                    ),
                    horizontal,
                    0,
                  ),
                  sliver: SliverToBoxAdapter(
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: CatalogViewModeButtonGroup(
                        mode: _viewMode,
                        onModeChanged: (CatalogViewMode mode) {
                          setState(() => _viewMode = mode);
                        },
                      ),
                    ),
                  ),
                ),
                _LibraryCatalogRegion(viewMode: _viewMode),
              ],
            ),
            ExpressiveLibraryScrollToTopButton(
              scrollController: _scrollController,
              horizontalPadding: horizontal,
            ),
          ],
        ),
      ),
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
            pageComicIds: ref.watch(
              libraryComicsCatalogControllerProvider.select(
                (AsyncValue<LibraryComicsCatalogState> async) {
                  final LibraryComicsCatalogState? catalog =
                      stableCatalogSnapshot(async);
                  return <String>[
                    for (final Comic comic
                        in catalog?.items ?? const <Comic>[])
                      comic.comicId,
                  ];
                },
              ),
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

/// 工具栏：只订阅 Tab 目标与两套目录的 totalCount。
class _LibraryCatalogToolbarSlot extends ConsumerWidget {
  const _LibraryCatalogToolbarSlot();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final LibraryDisplayTarget target = ref.watch(
      libraryPageFacadeProvider.select(
        (LibraryPageFacadeState state) => state.displayTarget,
      ),
    );
    final int comicCount = ref.watch(libraryDisplayedComicCountProvider);
    final int seriesCount = ref.watch(libraryDisplayedSeriesCountProvider);

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

/// 目录网格/列表 + 分页：订阅 catalog / selection / 阅读进度。
class _LibraryCatalogRegion extends ConsumerWidget {
  const _LibraryCatalogRegion({required this.viewMode});

  final CatalogViewMode viewMode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final LibraryDisplayTarget target = ref.watch(
      libraryPageFacadeProvider.select(
        (LibraryPageFacadeState state) => state.displayTarget,
      ),
    );
    final LibraryComicsCatalogState? comicsCatalog = stableCatalogSnapshot(
      ref.watch(libraryComicsCatalogControllerProvider),
    );
    final LibrarySeriesCatalogState? seriesCatalog = stableCatalogSnapshot(
      ref.watch(librarySeriesCatalogControllerProvider),
    );
    final CatalogSelectionState selection = ref.watch(catalogSelectionProvider);
    // 无条件订阅，避免 comics/series 分支切换时变更 watch 集合。
    final Map<String, int> readPages =
        ref.watch(comicReadPageIndexByIdProvider).value ??
        const <String, int>{};
    final PageLayoutSpec layout = PageLayoutSpec.of(context);
    final double horizontal = layout.horizontalInset;
    final LibraryPagination? pagination = switch (target) {
      LibraryDisplayTarget.comics => comicsCatalog?.pagination,
      LibraryDisplayTarget.series => seriesCatalog?.pagination,
    };

    final Widget catalogBody = _buildCatalogBody(
      context,
      ref,
      target: target,
      comicsCatalog: comicsCatalog,
      seriesCatalog: seriesCatalog,
      selection: selection,
      viewMode: viewMode,
      readPages: readPages,
    );

    return SliverPadding(
      padding: EdgeInsets.fromLTRB(
        horizontal,
        layout.headerToBodyGap,
        horizontal,
        LibraryBrowsePageMetrics.scrollBottomInset(layout.sizeClass),
      ),
      sliver: SliverToBoxAdapter(
        child: PeerContentTransition(
          switchKey: target,
          reverse: target == LibraryDisplayTarget.comics,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              catalogBody,
              if (pagination != null && pagination.totalPages > 1) ...<Widget>[
                SizedBox(height: Spacing.space16),
                Pagination(
                  page: pagination.page,
                  totalPages: pagination.totalPages,
                  totalItems: pagination.totalCount,
                  onPageChanged: (int page) {
                    ref
                        .read(libraryPageFacadeProvider.notifier)
                        .setPage(target, page);
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _openComicDetail(WidgetRef ref, String comicId) {
    ref.read(comicDetailReturnSeriesProvider.notifier).clear();
    ref
        .read(appRouterProvider)
        .pushNamed(
          ContentBreadcrumbLabels.comicDetail,
          pathParameters: <String, String>{'id': comicId},
        );
  }

  void _openSeriesDetail(WidgetRef ref, String seriesId) {
    ref
        .read(appRouterProvider)
        .push('/series/${Uri.encodeComponent(seriesId)}');
  }

  /// 列表模式：列数由窗口尺寸与平台决定（见 [comicListColumnCount]），与 Widgetbook Lab 一致。
  Widget _buildCatalogListBox(
    BuildContext context, {
    required int itemCount,
    required Widget Function(BuildContext context, int index) itemBuilder,
  }) {
    final PageLayoutSpec layout = PageLayoutSpec.of(context);
    final int columns = comicListColumnCount(layout.sizeClass);
    if (columns == 1) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          for (int index = 0; index < itemCount; index++)
            Padding(
              padding: EdgeInsets.only(
                bottom: index == itemCount - 1 ? 0 : layout.listItemGap,
              ),
              child: itemBuilder(context, index),
            ),
        ],
      );
    }
    final int rowCount = (itemCount + columns - 1) ~/ columns;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        for (int rowIndex = 0; rowIndex < rowCount; rowIndex++)
          Padding(
            padding: EdgeInsets.only(
              bottom: rowIndex == rowCount - 1 ? 0 : layout.listItemGap,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                for (int column = 0; column < columns; column++) ...<Widget>[
                  if (column > 0) SizedBox(width: layout.listItemGap),
                  Expanded(
                    child: rowIndex * columns + column < itemCount
                        ? itemBuilder(context, rowIndex * columns + column)
                        : const SizedBox.shrink(),
                  ),
                ],
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildCatalogBody(
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
          return const _LibraryLoadingBody();
        }
        if (comicsCatalog.items.isEmpty) {
          return _LibraryEmptyState(
            title: comicsCatalog.isComicTableEmpty
                ? l10n.libraryEmptyTitle
                : l10n.libraryNoMatchTitle,
          );
        }
        final List<Comic> comics = comicsCatalog.items;
        if (viewMode == CatalogViewMode.list) {
          return _buildCatalogListBox(
            context,
            itemCount: comics.length,
            itemBuilder: (BuildContext context, int index) {
              final Comic comic = comics[index];
              return ComicCardActions(
                comic: comic,
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
          );
        }
        return CatalogGridBox(
          itemCount: comics.length,
          itemBuilder: (BuildContext context, int index, _) {
            final Comic comic = comics[index];
            return ComicCardActions(
              key: ValueKey<String>(comic.comicId),
              comic: comic,
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
        );
      case LibraryDisplayTarget.series:
        if (seriesCatalog == null) {
          return const _LibraryLoadingBody();
        }
        if (seriesCatalog.items.isEmpty) {
          return _LibraryEmptyState(
            title: seriesCatalog.isSeriesTableEmpty
                ? l10n.librarySeriesEmptyTitle
                : l10n.libraryNoMatchTitle,
          );
        }
        final List<Series> series = seriesCatalog.items;
        if (viewMode == CatalogViewMode.list) {
          return _buildCatalogListBox(
            context,
            itemCount: series.length,
            itemBuilder: (BuildContext context, int index) {
              final Series s = series[index];
              return ComicListItem(
                title: s.name,
                pageLabel: context.l10n.seriesVolumeCountLabel(s.items.length),
                cover: SeriesCoverContent(
                  seriesId: s.id,
                  gridIndex: index,
                  coverViewportScope: CoverViewportScopes.library,
                ),
                onTap: () => _openSeriesDetail(ref, s.id),
              );
            },
          );
        }
        return CatalogGridBox(
          hasSubtitle: true,
          itemCount: series.length,
          itemBuilder: (BuildContext context, int index, _) {
            final Series s = series[index];
            return ComicCard(
              key: ValueKey<String>('library-series-${s.id}'),
              title: s.name,
              subtitle: context.l10n.seriesVolumeCountLabel(s.items.length),
              cover: SeriesCoverContent(
                seriesId: s.id,
                gridIndex: index,
                coverViewportScope: CoverViewportScopes.library,
              ),
              onTap: () => _openSeriesDetail(ref, s.id),
            );
          },
        );
    }
  }
}

class _LibraryLoadingBody extends StatelessWidget {
  const _LibraryLoadingBody();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 48),
      child: Center(child: CircularProgressIndicator()),
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
