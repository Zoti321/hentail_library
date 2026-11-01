import 'package:flutter/material.dart';
import 'package:hentai_library/shared/ui/layout/breakpoints.dart';
import 'package:hentai_library/shared/ui/layout/catalog_grid.dart';
import 'package:hentai_library/shared/ui/layout/catalog_grid_metrics.dart';
import 'package:hentai_library/shared/ui/layout/catalog_list_layout.dart';
import 'package:hentai_library/shared/ui/layout/library_browse_page_metrics.dart';
import 'package:hentai_library/features/library_browse/presentation/patterns/library/library_catalog_toolbar.dart';
import 'package:hentai_library/features/library_browse/presentation/patterns/library/lab_catalog_item_preview.dart';
import 'package:hentai_library/features/library_browse/presentation/patterns/library/library_page_header.dart';
import 'package:hentai_library/shared/ui/patterns/shared/md3e_page_header.dart';
import 'package:hentai_library/shared/ui/widgets/actions/catalog_view_mode_button_group.dart';
import 'package:hentai_library/shared/ui/widgets/catalog/comic_card.dart';
import 'package:hentai_library/shared/ui/widgets/catalog/comic_list_item.dart';
import 'package:hentai_library/shared/ui/widgets/navigation/expressive_library_scroll_to_top_button.dart';
import 'package:hentai_library/shared/ui/widgets/pagination/pagination.dart';
import 'package:hentai_library/shared/domain/models/enums.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

/// 漫画库页 Lab 壳层：粘滞页头 + 可滚动目录区（视图切换 / 网格·列表 / 分页）。
class Md3eLibraryBrowsePage extends StatefulWidget {
  const Md3eLibraryBrowsePage({
    super.key,
    required this.displayTarget,
    required this.viewMode,
    required this.filterSortActive,
    this.onDisplayTargetChanged,
    this.onViewModeChanged,
    this.onFilterSort,
    this.pageSize,
    this.onPageSizeChanged,
    this.overflowMenuEntries = const <M3EMenuNode>[],
    this.itemCount = 12,
    this.comicCount = 1284,
    this.seriesCount = 96,
    this.page = 1,
    this.totalPages = 1,
    this.onPageChanged,
    this.scrollController,
    this.hideScrollToTop = false,
    this.onCatalogItemTap,
    this.libraryDisplayName,
  });

  final LibraryDisplayTarget displayTarget;
  final Md3eCatalogViewMode viewMode;
  final bool filterSortActive;
  final ValueChanged<LibraryDisplayTarget>? onDisplayTargetChanged;
  final ValueChanged<Md3eCatalogViewMode>? onViewModeChanged;
  final VoidCallback? onFilterSort;
  final int? pageSize;
  final ValueChanged<int>? onPageSizeChanged;
  final List<M3EMenuNode> overflowMenuEntries;
  final int itemCount;
  final int comicCount;
  final int seriesCount;

  /// Current catalog page (1-based).
  final int page;
  final int totalPages;
  final ValueChanged<int>? onPageChanged;

  final ScrollController? scrollController;
  final bool hideScrollToTop;

  /// Lab：目录卡片点击（index 与网格/列表一致；生产由路由层处理）。
  final ValueChanged<int>? onCatalogItemTap;

  /// Lab shell：当前库显示名（rehearsal for Current library display name）。
  final String? libraryDisplayName;

  @override
  State<Md3eLibraryBrowsePage> createState() => _Md3eLibraryBrowsePageState();
}

class _Md3eLibraryBrowsePageState extends State<Md3eLibraryBrowsePage> {
  late final ScrollController _scrollController;
  late final bool _ownsScrollController;

  @override
  void initState() {
    super.initState();
    _ownsScrollController = widget.scrollController == null;
    _scrollController = widget.scrollController ?? ScrollController();
  }

  @override
  void didUpdateWidget(covariant Md3eLibraryBrowsePage oldWidget) {
    super.didUpdateWidget(oldWidget);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  @override
  void dispose() {
    if (_ownsScrollController) {
      _scrollController.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double viewportWidth = MediaQuery.sizeOf(context).width;
    final Md3eWindowSizeClass sizeClass = Md3eWindowSizeClass.fromWidth(
      viewportWidth,
    );
    final double horizontal =
        Md3eLibraryBrowsePageMetrics.contentHorizontalPadding(sizeClass);

    final Widget header = Md3eLibraryPageHeader(
      title: widget.libraryDisplayName,
      filterSortActive: widget.filterSortActive,
      pageSize: widget.pageSize,
      onPageSizeChanged: widget.onPageSizeChanged,
      overflowMenuEntries: widget.overflowMenuEntries,
      onFilterSort: widget.onFilterSort,
    );

    return Stack(
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
            if (widget.onDisplayTargetChanged != null)
              SliverPadding(
                padding: EdgeInsets.fromLTRB(
                  horizontal,
                  Md3eLibraryBrowsePageMetrics.catalogToolbarTopSpacing(
                    sizeClass,
                  ),
                  horizontal,
                  0,
                ),
                sliver: SliverToBoxAdapter(
                  child: Md3eLibraryCatalogToolbar(
                    displayTarget: widget.displayTarget,
                    comicCount: widget.comicCount,
                    seriesCount: widget.seriesCount,
                    onDisplayTargetChanged: widget.onDisplayTargetChanged!,
                  ),
                ),
              ),
            SliverPadding(
              padding: EdgeInsets.fromLTRB(
                horizontal,
                widget.onDisplayTargetChanged != null
                    ? Md3eLibraryBrowsePageMetrics.catalogToolbarToViewModeSpacing(
                        sizeClass,
                      )
                    : Md3eLibraryBrowsePageMetrics.catalogToolbarTopSpacing(
                        sizeClass,
                      ),
                horizontal,
                0,
              ),
              sliver: SliverToBoxAdapter(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Md3eCatalogViewModeButtonGroup(
                    mode: widget.viewMode,
                    onModeChanged: widget.onViewModeChanged ?? (_) {},
                  ),
                ),
              ),
            ),
            SliverPadding(
              padding: EdgeInsets.only(
                top: Md3eLibraryBrowsePageMetrics.catalogBodyTopSpacing(
                  sizeClass,
                ),
              ),
              sliver: switch (widget.viewMode) {
                Md3eCatalogViewMode.grid => Md3eCatalogGridSliver(
                  itemCount: widget.itemCount,
                  itemBuilder: _buildGridCard,
                ),
                Md3eCatalogViewMode.list => _Md3eLibraryBrowseListSliver(
                  itemCount: widget.itemCount,
                  horizontalPadding: horizontal,
                  displayTarget: widget.displayTarget,
                  onCatalogItemTap: widget.onCatalogItemTap,
                ),
              },
            ),
            SliverPadding(
              padding: EdgeInsets.fromLTRB(
                horizontal,
                Md3eLibraryBrowsePageMetrics.paginationVerticalSpacing(
                  sizeClass,
                ),
                horizontal,
                Md3eLibraryBrowsePageMetrics.scrollBottomInset(sizeClass),
              ),
              sliver: SliverToBoxAdapter(
                child: Md3ePagination(
                  page: widget.page,
                  totalPages: widget.totalPages,
                  onPageChanged: widget.onPageChanged ?? (_) {},
                ),
              ),
            ),
          ],
        ),
        Md3eLibraryScrollToTopButton(
          scrollController: _scrollController,
          horizontalPadding: horizontal,
          hidden: widget.hideScrollToTop,
        ),
      ],
    );
  }

  Widget _buildGridCard(
    BuildContext context,
    int index,
    Md3eCatalogGridLayout _,
  ) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final double? readProgress =
        widget.displayTarget == LibraryDisplayTarget.comics && index.isEven
        ? ((index % 9) + 1) / 10
        : null;
    final _Md3eLibraryBrowseCatalogItemCopy copy =
        _Md3eLibraryBrowseCatalogItemCopy.fromPreview(
          Md3eLabCatalogItemPreview.forIndex(
            displayTarget: widget.displayTarget,
            index: index,
          ),
        );
    return Md3eComicCard(
      title: copy.title,
      subtitle: copy.subtitle,
      readProgress: readProgress,
      cover: ColoredBox(
        color: scheme.surfaceContainerHigh,
        child: Center(
          child: Icon(Icons.image_outlined, color: scheme.onSurfaceVariant),
        ),
      ),
      onTap: () => widget.onCatalogItemTap?.call(index),
    );
  }
}

/// Lab 占位目录文案（漫画 / 系列卡片共用 [Md3eComicCard] / [Md3eComicListItem]）。
@immutable
class _Md3eLibraryBrowseCatalogItemCopy {
  const _Md3eLibraryBrowseCatalogItemCopy({
    required this.title,
    required this.subtitle,
    this.listAuthor,
  });

  final String title;
  final String subtitle;
  final String? listAuthor;

  static _Md3eLibraryBrowseCatalogItemCopy fromPreview(
    Md3eLabCatalogItemPreview preview,
  ) {
    return _Md3eLibraryBrowseCatalogItemCopy(
      title: preview.title,
      subtitle: preview.subtitle,
      listAuthor: preview.listAuthor,
    );
  }
}

class _Md3eLibraryBrowseListSliver extends StatelessWidget {
  const _Md3eLibraryBrowseListSliver({
    required this.itemCount,
    required this.horizontalPadding,
    required this.displayTarget,
    this.onCatalogItemTap,
  });

  final int itemCount;
  final double horizontalPadding;
  final LibraryDisplayTarget displayTarget;
  final ValueChanged<int>? onCatalogItemTap;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final Md3eWindowSizeClass window = md3eWindowSizeClassOf(context);
    final int columns = md3eComicListColumnCount(window);

    return SliverPadding(
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
      sliver: switch (columns) {
        1 => SliverList(
          delegate: SliverChildBuilderDelegate(
            (BuildContext context, int index) => _Md3eLibraryBrowseListItem(
              scheme: scheme,
              index: index,
              displayTarget: displayTarget,
              onCatalogItemTap: onCatalogItemTap,
            ),
            childCount: itemCount,
          ),
        ),
        _ => SliverList(
          delegate: SliverChildBuilderDelegate((
            BuildContext context,
            int rowIndex,
          ) {
            final int leftIndex = rowIndex * 2;
            final int rightIndex = leftIndex + 1;
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(
                  child: _Md3eLibraryBrowseListItem(
                    scheme: scheme,
                    index: leftIndex,
                    displayTarget: displayTarget,
                    onCatalogItemTap: onCatalogItemTap,
                  ),
                ),
                Expanded(
                  child: rightIndex < itemCount
                      ? _Md3eLibraryBrowseListItem(
                          scheme: scheme,
                          index: rightIndex,
                          displayTarget: displayTarget,
                          onCatalogItemTap: onCatalogItemTap,
                        )
                      : const SizedBox.shrink(),
                ),
              ],
            );
          }, childCount: (itemCount + 1) ~/ 2),
        ),
      },
    );
  }
}

class _Md3eLibraryBrowseListItem extends StatelessWidget {
  const _Md3eLibraryBrowseListItem({
    required this.scheme,
    required this.index,
    required this.displayTarget,
    this.onCatalogItemTap,
  });

  final ColorScheme scheme;
  final int index;
  final LibraryDisplayTarget displayTarget;
  final ValueChanged<int>? onCatalogItemTap;

  @override
  Widget build(BuildContext context) {
    final _Md3eLibraryBrowseCatalogItemCopy copy =
        _Md3eLibraryBrowseCatalogItemCopy.fromPreview(
          Md3eLabCatalogItemPreview.forIndex(
            displayTarget: displayTarget,
            index: index,
          ),
        );
    final double? readProgress =
        displayTarget == LibraryDisplayTarget.comics && index.isEven
        ? ((index % 9) + 1) / 10
        : null;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Md3eComicListItem(
        title: copy.title,
        author: copy.listAuthor ?? '',
        pageLabel: copy.subtitle,
        readProgress: readProgress,
        moreMenuEntries: const <Md3eComicListMoreMenuEntry>[
          Md3eComicListMoreMenuEntry(label: '继续阅读'),
          Md3eComicListMoreMenuEntry(label: '编辑元数据'),
          Md3eComicListMoreMenuEntry(label: '删除'),
        ],
        cover: ColoredBox(
          color: scheme.surfaceContainerHigh,
          child: Center(
            child: Icon(
              Icons.image_outlined,
              color: scheme.onSurfaceVariant,
              size: 20,
            ),
          ),
        ),
        onTap: () => onCatalogItemTap?.call(index),
      ),
    );
  }
}
