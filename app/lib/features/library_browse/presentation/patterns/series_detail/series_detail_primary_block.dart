import 'package:flutter/material.dart';
import 'package:hentai_library/shared/ui/layout/breakpoints.dart';
import 'package:hentai_library/shared/ui/layout/series_detail_page_metrics.dart';
import 'package:hentai_library/features/library_browse/presentation/views/series_detail_md3e/series_detail_page_entry.dart';
import 'package:hentai_library/features/library_browse/presentation/patterns/comic_detail/comic_detail_primary_row_layout.dart';
import 'package:hentai_library/features/library_browse/presentation/patterns/series_detail/series_detail_primary_column.dart';
import 'package:hentai_library/shared/ui/widgets/catalog/comic_detail_cover.dart';

/// 系列首屏：封面 + 主信息列。
class Md3eSeriesDetailPrimaryBlock extends StatelessWidget {
  const Md3eSeriesDetailPrimaryBlock({super.key, required this.entry});

  final Md3eSeriesDetailEntry entry;

  @override
  Widget build(BuildContext context) {
    final Md3eWindowSizeClass sizeClass = md3eWindowSizeClassOf(context);

    return Md3eComicDetailPrimaryRowLayout(
      coverWidth: Md3eSeriesDetailPageMetrics.coverWidth(sizeClass),
      rowGap: Md3eSeriesDetailPageMetrics.primaryRowGap(sizeClass),
      narrowBreakpoint: Md3eSeriesDetailPageMetrics.primaryRowNarrowBreakpoint,
      cover: Md3eComicDetailCover(child: entry.cover),
      content: Md3eSeriesDetailPrimaryColumn(entry: entry),
    );
  }
}
