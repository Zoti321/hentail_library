import 'package:flutter/material.dart';
import 'package:hentai_library/md3e/layout/md3e_breakpoints.dart';
import 'package:hentai_library/md3e/layout/md3e_series_detail_page_metrics.dart';
import 'package:hentai_library/md3e/pages/md3e_series_detail_entry.dart';
import 'package:hentai_library/md3e/patterns/comic_detail/md3e_comic_detail_primary_row_layout.dart';
import 'package:hentai_library/md3e/patterns/series_detail/md3e_series_detail_primary_column.dart';
import 'package:hentai_library/md3e/widgets/catalog/md3e_comic_detail_cover.dart';

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
