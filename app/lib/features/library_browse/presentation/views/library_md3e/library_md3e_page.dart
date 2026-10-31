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
import 'package:hentai_library/md3e/layout/md3e_breakpoints.dart';
import 'package:hentai_library/md3e/layout/md3e_catalog_grid.dart';
import 'package:hentai_library/md3e/layout/md3e_library_browse_page_metrics.dart';
import 'package:hentai_library/md3e/patterns/library/md3e_library_catalog_toolbar.dart';
import 'package:hentai_library/md3e/patterns/library/md3e_library_page_header.dart';
import 'package:hentai_library/md3e/patterns/library/md3e_library_pinned_header_delegate.dart';
import 'package:hentai_library/md3e/theme/md3e_theme.dart';
import 'package:hentai_library/md3e/widgets/catalog/md3e_comic_card.dart';
import 'package:hentai_library/md3e/widgets/navigation/md3e_library_scroll_to_top_button.dart';
import 'package:hentai_library/md3e/widgets/pagination/md3e_pagination.dart';
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
  final GlobalKey _headerMeasureKey = GlobalKey();
  double? _headerExtent;

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

    WidgetsBinding.instance.addPostFrameCallback(_measureHeaderExtent);
    final Widget header = KeyedSubtree(
      key: _headerMeasureKey,
      child: Padding(
        padding: EdgeInsets.fromLTRB(horizontal, 16, horizontal, 0),
        child: selection.active
            ? Md3eLibrarySelectionHeader(
                pageComicIds: <String>[
                  for (final Comic comic
                      in comicsCatalog?.items ?? const <Comic>[])
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
              ),
      ),
    );

    // 生产路径无 Md3eThemeScope，补上应用字体（同首页 HomeMd3ePage）。
    return M3ETheme(
      data: md3eWithAppFontFamily(M3ETheme.of(context)),
      child: Scaffold(
        body: Stack(
          children: <Widget>[
            CustomScrollView(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: <Widget>[
                if (_headerExtent == null)
                  SliverToBoxAdapter(child: header)
                else
                  SliverPersistentHeader(
                    pinned: true,
                    delegate: Md3eLibraryPinnedHeaderDelegate(
                      extent: _headerExtent!,
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
                      onDisplayTargetChanged:
                          facadeNotifier.selectDisplayTarget,
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
      ),
    );
  }

  List<Widget> _buildCatalog(
    BuildContext context, {
    required LibraryDisplayTarget target,
    required double horizontal,
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
