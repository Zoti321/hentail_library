import 'package:flutter/material.dart';
import 'package:hentai_library/shared/ui/layout/breakpoints.dart';
import 'package:hentai_library/features/series/presentation/patterns/series_detail/series_detail_page_metrics.dart';
import 'package:hentai_library/features/series/presentation/views/series_detail/series_detail_view_object.dart';
import 'package:hentai_library/features/series/presentation/patterns/series_detail/series_detail_summary_meta_row.dart';
import 'package:hentai_library/shared/ui/layout/comic_detail_title.dart';

/// 系列封面右侧：标题 + 摘要元信息。
class SeriesDetailPrimaryColumn extends StatelessWidget {
  const SeriesDetailPrimaryColumn({super.key, required this.entry});

  final SeriesDetailViewObject entry;

  @override
  Widget build(BuildContext context) {
    final WindowSizeClass sizeClass = windowSizeClassOf(context);
    final double columnGap = SeriesDetailPageMetrics.primaryColumnSpacing(
      sizeClass,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: columnGap,
      children: <Widget>[
        ComicDetailTitle(title: entry.title),
        SeriesDetailSummaryMetaRow(entry: entry),
      ],
    );
  }
}
