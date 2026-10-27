import 'package:flutter/material.dart';
import 'package:hentai_library/md3e/layout/md3e_breakpoints.dart';
import 'package:hentai_library/md3e/layout/md3e_catalog_grid.dart';
import 'package:hentai_library/md3e/layout/md3e_catalog_grid_metrics.dart';
import 'package:hentai_library/md3e/layout/md3e_catalog_list_layout.dart';
import 'package:hentai_library/md3e/layout/md3e_library_browse_page_metrics.dart';
import 'package:hentai_library/md3e/patterns/md3e_library_catalog_toolbar.dart';
import 'package:hentai_library/md3e/patterns/md3e_library_page_header.dart';
import 'package:hentai_library/md3e/patterns/md3e_library_pinned_header_delegate.dart';
import 'package:hentai_library/md3e/widgets/actions/md3e_catalog_view_mode_button_group.dart';
import 'package:hentai_library/md3e/widgets/catalog/md3e_comic_card.dart';
import 'package:hentai_library/md3e/widgets/catalog/md3e_comic_list_item.dart';
import 'package:hentai_library/md3e/widgets/navigation/md3e_library_scroll_to_top_button.dart';
import 'package:hentai_library/md3e/widgets/pagination/md3e_pagination.dart';
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
  });

  final Md3eLibraryDisplayTarget displayTarget;
  final Md3eCatalogViewMode viewMode;
  final bool filterSortActive;
  final ValueChanged<Md3eLibraryDisplayTarget>? onDisplayTargetChanged;
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

  @override
  State<Md3eLibraryBrowsePage> createState() => _Md3eLibraryBrowsePageState();
}

class _Md3eLibraryBrowsePageState extends State<Md3eLibraryBrowsePage> {
  final GlobalKey _headerMeasureKey = GlobalKey();
  late final ScrollController _scrollController;
  late final bool _ownsScrollController;
  double? _headerExtent;

  @override
  void initState() {
    super.initState();
    _ownsScrollController = widget.scrollController == null;
    _scrollController = widget.scrollController ?? ScrollController();
    WidgetsBinding.instance.addPostFrameCallback(_measureHeaderExtent);
  }

  @override
  void didUpdateWidget(covariant Md3eLibraryBrowsePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    WidgetsBinding.instance.addPostFrameCallback(_measureHeaderExtent);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    WidgetsBinding.instance.addPostFrameCallback(_measureHeaderExtent);
  }

  @override
  void dispose() {
    if (_ownsScrollController) {
      _scrollController.dispose();
    }
    super.dispose();
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
    final double viewportWidth = MediaQuery.sizeOf(context).width;
    final Md3eWindowSizeClass sizeClass =
        Md3eWindowSizeClass.fromWidth(viewportWidth);
    final double horizontal =
        Md3eLibraryBrowsePageMetrics.contentHorizontalPadding(sizeClass);

    final Widget header = KeyedSubtree(
      key: _headerMeasureKey,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: horizontal),
        child: Md3eLibraryPageHeader(
          displayTarget: widget.displayTarget,
          filterSortActive: widget.filterSortActive,
          pageSize: widget.pageSize,
          onPageSizeChanged: widget.onPageSizeChanged,
          overflowMenuEntries: widget.overflowMenuEntries,
          onFilterSort: widget.onFilterSort,
        ),
      ),
    );

    return Stack(
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
        index.isOdd ? null : ((index % 9) + 1) / 10;
    return Md3eComicCard(
      title: '示例本子 ${index + 1}',
      subtitle: '${64 + index * 8} 页',
      readProgress: readProgress,
      cover: ColoredBox(
        color: scheme.surfaceContainerHigh,
        child: Center(
          child: Icon(
            Icons.image_outlined,
            color: scheme.onSurfaceVariant,
          ),
        ),
      ),
      onTap: () {},
    );
  }
}

class _Md3eLibraryBrowseListSliver extends StatelessWidget {
  const _Md3eLibraryBrowseListSliver({
    required this.itemCount,
    required this.horizontalPadding,
  });

  final int itemCount;
  final double horizontalPadding;

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
            (BuildContext context, int index) =>
                _Md3eLibraryBrowseListItem(scheme: scheme, index: index),
            childCount: itemCount,
          ),
        ),
        _ => SliverList(
          delegate: SliverChildBuilderDelegate(
            (BuildContext context, int rowIndex) {
              final int leftIndex = rowIndex * 2;
              final int rightIndex = leftIndex + 1;
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(
                    child: _Md3eLibraryBrowseListItem(
                      scheme: scheme,
                      index: leftIndex,
                    ),
                  ),
                  Expanded(
                    child: rightIndex < itemCount
                        ? _Md3eLibraryBrowseListItem(
                            scheme: scheme,
                            index: rightIndex,
                          )
                        : const SizedBox.shrink(),
                  ),
                ],
              );
            },
            childCount: (itemCount + 1) ~/ 2,
          ),
        ),
      },
    );
  }
}

class _Md3eLibraryBrowseListItem extends StatelessWidget {
  const _Md3eLibraryBrowseListItem({
    required this.scheme,
    required this.index,
  });

  final ColorScheme scheme;
  final int index;

  @override
  Widget build(BuildContext context) {
    final double? readProgress =
        index.isOdd ? null : ((index % 9) + 1) / 10;
    return Md3eComicListItem(
      title: '示例本子 ${index + 1}',
      author: '作者 ${index % 5 + 1}',
      pageLabel: '${64 + index * 8} 页',
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
      onTap: () {},
    );
  }
}
