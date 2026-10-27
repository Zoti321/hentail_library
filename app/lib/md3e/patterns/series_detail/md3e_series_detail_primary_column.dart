import 'package:flutter/material.dart';
import 'package:hentai_library/md3e/layout/md3e_breakpoints.dart';
import 'package:hentai_library/md3e/layout/md3e_series_detail_page_metrics.dart';
import 'package:hentai_library/md3e/pages/md3e_series_detail_entry.dart';
import 'package:hentai_library/md3e/patterns/series_detail/md3e_series_detail_summary_meta_row.dart';
import 'package:hentai_library/md3e/patterns/comic_detail/md3e_comic_detail_title.dart';

/// 系列封面右侧：标题 + 摘要元信息。
class Md3eSeriesDetailPrimaryColumn extends StatelessWidget {
  const Md3eSeriesDetailPrimaryColumn({super.key, required this.entry});

  final Md3eSeriesDetailEntry entry;

  @override
  Widget build(BuildContext context) {
    final Md3eWindowSizeClass sizeClass = md3eWindowSizeClassOf(context);
    final double columnGap =
        Md3eSeriesDetailPageMetrics.primaryColumnSpacing(sizeClass);

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
