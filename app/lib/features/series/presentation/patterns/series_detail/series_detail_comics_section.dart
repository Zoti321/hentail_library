import 'package:flutter/material.dart';
import 'package:hentai_library/shared/ui/layout/breakpoints.dart';
import 'package:hentai_library/features/series/presentation/patterns/series_detail/series_detail_page_metrics.dart';
import 'package:hentai_library/features/series/presentation/views/series_detail/series_detail_view_object.dart';
import 'package:hentai_library/features/series/presentation/patterns/series_detail/series_detail_comics_grid.dart';
import 'package:hentai_library/shared/ui/widgets/pagination/pagination.dart';

/// 系列漫画列表区：网格 + 底部分页。
class SeriesDetailComicsSection extends StatelessWidget {
  const SeriesDetailComicsSection({
    super.key,
    this.gridSectionKey,
    required this.pageItems,
    required this.page,
    required this.totalPages,
    required this.onPageChanged,
    this.onComicTap,
  });

  final Key? gridSectionKey;
  final List<SeriesDetailComicItem> pageItems;
  final int page;
  final int totalPages;
  final ValueChanged<int> onPageChanged;
  final ValueChanged<int>? onComicTap;

  @override
  Widget build(BuildContext context) {
    final WindowSizeClass sizeClass = windowSizeClassOf(context);
    final double paginationGap =
        SeriesDetailPageMetrics.paginationVerticalSpacing(sizeClass);

    return SliverMainAxisGroup(
      slivers: <Widget>[
        SliverToBoxAdapter(key: gridSectionKey, child: const SizedBox.shrink()),
        SeriesDetailComicsGrid(items: pageItems, onComicTap: onComicTap),
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.only(top: paginationGap),
            child: Align(
              alignment: Alignment.centerRight,
              child: Pagination(
                page: page,
                totalPages: totalPages,
                onPageChanged: onPageChanged,
              ),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: SizedBox(height: SeriesDetailPageMetrics.scrollBottomInset),
        ),
      ],
    );
  }
}
