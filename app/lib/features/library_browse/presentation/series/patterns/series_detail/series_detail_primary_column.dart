import 'package:flutter/material.dart';
import 'package:hentai_library/shared/ui/layout/breakpoints.dart';
import 'package:hentai_library/shared/ui/layout/series_detail_page_metrics.dart';
import 'package:hentai_library/features/library_browse/presentation/series/views/series_detail_md3e/series_detail_page_entry.dart';
import 'package:hentai_library/features/library_browse/presentation/series/patterns/series_detail/series_detail_summary_meta_row.dart';
import 'package:hentai_library/features/library_browse/presentation/comic/patterns/comic_detail/comic_detail_title.dart';

/// 系列封面右侧：标题 + 摘要元信息。
class Md3eSeriesDetailPrimaryColumn extends StatelessWidget {
  const Md3eSeriesDetailPrimaryColumn({super.key, required this.entry});

  final Md3eSeriesDetailEntry entry;

  @override
  Widget build(BuildContext context) {
    final Md3eWindowSizeClass sizeClass = md3eWindowSizeClassOf(context);
    final double columnGap = Md3eSeriesDetailPageMetrics.primaryColumnSpacing(
      sizeClass,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: columnGap,
      children: <Widget>[
        Md3eComicDetailTitle(title: entry.title),
        Md3eSeriesDetailSummaryMetaRow(entry: entry),
      ],
    );
  }
}
