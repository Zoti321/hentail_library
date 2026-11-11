import 'package:flutter/material.dart';
import 'package:hentai_library/design-system/design_system.dart';
import 'package:hentai_library/shared/ui/layout/comic_detail_page_metrics.dart';
import 'package:hentai_library/features/comic/presentation/views/comic_detail/comic_detail_view_object.dart';
import 'package:hentai_library/features/comic/presentation/patterns/comic_detail/comic_detail_description.dart';
import 'package:hentai_library/features/comic/presentation/patterns/comic_detail/comic_detail_primary_actions.dart';
import 'package:hentai_library/features/comic/presentation/patterns/comic_detail/comic_detail_summary_meta_row.dart';
import 'package:hentai_library/shared/ui/layout/comic_detail_title.dart';

/// 封面右侧：标题 + 摘要 + 操作 + 简介。
class ComicDetailPrimaryColumn extends StatelessWidget {
  const ComicDetailPrimaryColumn({
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
    final double columnGap = ComicDetailPageMetrics.primaryColumnSpacing(
      sizeClass,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: columnGap,
      children: <Widget>[
        ComicDetailTitle(title: entry.title),
        ComicDetailSummaryMetaRow(entry: entry),
        ComicDetailPrimaryActions(
          onRead: onRead,
          onReadIncognito: onReadIncognito,
        ),
        ComicDetailDescription(text: entry.description),
      ],
    );
  }
}
