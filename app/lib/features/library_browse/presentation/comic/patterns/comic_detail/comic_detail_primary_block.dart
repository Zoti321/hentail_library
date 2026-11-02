import 'package:flutter/material.dart';
import 'package:hentai_library/shared/ui/layout/breakpoints.dart';
import 'package:hentai_library/shared/ui/layout/comic_detail_page_metrics.dart';
import 'package:hentai_library/features/library_browse/presentation/comic/views/comic_detail_md3e/comic_detail_page_entry.dart';
import 'package:hentai_library/features/library_browse/presentation/comic/patterns/comic_detail/comic_detail_primary_column.dart';
import 'package:hentai_library/features/library_browse/presentation/comic/patterns/comic_detail/comic_detail_primary_row_layout.dart';
import 'package:hentai_library/shared/ui/widgets/catalog/comic_detail_cover.dart';

/// 详情首屏：封面 + 主信息列（响应式横竖排）。
class Md3eComicDetailPrimaryBlock extends StatelessWidget {
  const Md3eComicDetailPrimaryBlock({
    super.key,
    required this.entry,
    this.onRead,
    this.onReadIncognito,
  });

  final Md3eComicDetailEntry entry;
  final VoidCallback? onRead;
  final VoidCallback? onReadIncognito;

  @override
  Widget build(BuildContext context) {
    final Md3eWindowSizeClass sizeClass = md3eWindowSizeClassOf(context);

    return Md3eComicDetailPrimaryRowLayout(
      coverWidth: Md3eComicDetailPageMetrics.coverWidth(sizeClass),
      rowGap: Md3eComicDetailPageMetrics.primaryRowGap(sizeClass),
      narrowBreakpoint: Md3eComicDetailPageMetrics.primaryRowNarrowBreakpoint,
      cover: Md3eComicDetailCover(child: entry.cover),
      content: Md3eComicDetailPrimaryColumn(
        entry: entry,
        onRead: onRead,
        onReadIncognito: onReadIncognito,
      ),
    );
  }
}
