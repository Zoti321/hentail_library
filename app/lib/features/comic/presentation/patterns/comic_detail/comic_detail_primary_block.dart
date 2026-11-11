import 'package:flutter/material.dart';
import 'package:hentai_library/design-system/design_system.dart';
import 'package:hentai_library/shared/ui/layout/comic_detail_page_metrics.dart';
import 'package:hentai_library/features/comic/presentation/views/comic_detail/comic_detail_view_object.dart';
import 'package:hentai_library/features/comic/presentation/patterns/comic_detail/comic_detail_primary_column.dart';
import 'package:hentai_library/shared/ui/layout/comic_detail_primary_row_layout.dart';
import 'package:hentai_library/shared/ui/widgets/catalog/comic_detail_cover.dart';

/// 详情首屏：封面 + 主信息列（响应式横竖排）。
class ComicDetailPrimaryBlock extends StatelessWidget {
  const ComicDetailPrimaryBlock({
    super.key,
    required this.entry,
    this.onRead,
    this.onReadIncognito,
  });

  final ComicDetailViewObject entry;
  final VoidCallback? onRead;
  final VoidCallback? onReadIncognito;

  @override
  Widget build(BuildContext context) {
    final WindowSizeClass sizeClass = windowSizeClassOf(context);

    return ComicDetailPrimaryRowLayout(
      coverWidth: ComicDetailPageMetrics.coverWidth(sizeClass),
      rowGap: ComicDetailPageMetrics.primaryRowGap(sizeClass),
      narrowBreakpoint: ComicDetailPageMetrics.primaryRowNarrowBreakpoint,
      cover: AppComicDetailCover(child: entry.cover),
      content: ComicDetailPrimaryColumn(
        entry: entry,
        onRead: onRead,
        onReadIncognito: onReadIncognito,
      ),
    );
  }
}
