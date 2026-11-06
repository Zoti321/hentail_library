import 'package:flutter/material.dart';
import 'package:hentai_library/shared/ui/layout/breakpoints.dart';
import 'package:hentai_library/shared/ui/layout/series_detail_page_metrics.dart';
import 'package:hentai_library/features/series/presentation/views/series_detail/series_detail_view_object.dart';
import 'package:hentai_library/features/comic/public/ui/comic_detail_layout.dart';
import 'package:hentai_library/features/series/presentation/patterns/series_detail/series_detail_primary_column.dart';
import 'package:hentai_library/shared/ui/widgets/catalog/comic_detail_cover.dart';

/// 系列首屏：封面 + 主信息列。
class SeriesDetailPrimaryBlock extends StatelessWidget {
  const SeriesDetailPrimaryBlock({super.key, required this.entry});

  final SeriesDetailViewObject entry;

  @override
  Widget build(BuildContext context) {
    final WindowSizeClass sizeClass = windowSizeClassOf(context);

    return ComicDetailPrimaryRowLayout(
      coverWidth: SeriesDetailPageMetrics.coverWidth(sizeClass),
      rowGap: SeriesDetailPageMetrics.primaryRowGap(sizeClass),
      narrowBreakpoint: SeriesDetailPageMetrics.primaryRowNarrowBreakpoint,
      cover: AppComicDetailCover(child: entry.cover),
      content: SeriesDetailPrimaryColumn(entry: entry),
    );
  }
}
