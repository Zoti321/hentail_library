import 'package:flutter/material.dart';
import 'package:hentai_library/md3e/layout/md3e_breakpoints.dart';
import 'package:hentai_library/md3e/layout/md3e_series_detail_page_metrics.dart';
import 'package:hentai_library/md3e/pages/md3e_series_detail_entry.dart';
import 'package:hentai_library/md3e/patterns/series_detail/md3e_series_detail_comics_grid.dart';
import 'package:hentai_library/md3e/widgets/pagination/md3e_pagination.dart';

/// 系列漫画列表区：网格 + 底部分页。
class Md3eSeriesDetailComicsSection extends StatelessWidget {
  const Md3eSeriesDetailComicsSection({
    super.key,
    this.gridSectionKey,
    required this.pageItems,
    required this.page,
    required this.totalPages,
    required this.onPageChanged,
    this.onComicTap,
  });

  final Key? gridSectionKey;
  final List<Md3eSeriesDetailComicItem> pageItems;
  final int page;
  final int totalPages;
  final ValueChanged<int> onPageChanged;
  final ValueChanged<int>? onComicTap;

  @override
  Widget build(BuildContext context) {
    final Md3eWindowSizeClass sizeClass = md3eWindowSizeClassOf(context);
    final double paginationGap =
        Md3eSeriesDetailPageMetrics.paginationVerticalSpacing(sizeClass);

    return SliverMainAxisGroup(
      slivers: <Widget>[
        SliverToBoxAdapter(
          key: gridSectionKey,
          child: const SizedBox.shrink(),
        ),
        Md3eSeriesDetailComicsGrid(
          items: pageItems,
          onComicTap: onComicTap,
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.only(top: paginationGap),
            child: Align(
              alignment: Alignment.centerRight,
              child: Md3ePagination(
                page: page,
                totalPages: totalPages,
                onPageChanged: onPageChanged,
              ),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: SizedBox(
            height: Md3eSeriesDetailPageMetrics.scrollBottomInset,
          ),
        ),
      ],
    );
  }
}
