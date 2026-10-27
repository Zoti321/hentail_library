import 'package:flutter/material.dart';
import 'package:hentai_library/md3e/layout/md3e_breakpoints.dart';
import 'package:hentai_library/md3e/layout/md3e_comic_detail_page_metrics.dart';
import 'package:hentai_library/md3e/pages/md3e_comic_detail_entry.dart';
import 'package:hentai_library/md3e/patterns/comic_detail/md3e_comic_detail_description.dart';
import 'package:hentai_library/md3e/patterns/comic_detail/md3e_comic_detail_primary_actions.dart';
import 'package:hentai_library/md3e/patterns/comic_detail/md3e_comic_detail_summary_meta_row.dart';
import 'package:hentai_library/md3e/patterns/comic_detail/md3e_comic_detail_title.dart';

/// 封面右侧：标题 + 摘要 + 操作 + 简介。
class Md3eComicDetailPrimaryColumn extends StatelessWidget {
  const Md3eComicDetailPrimaryColumn({
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
    final double columnGap =
        Md3eComicDetailPageMetrics.primaryColumnSpacing(sizeClass);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: columnGap,
      children: <Widget>[
        Md3eComicDetailTitle(title: entry.title),
        Md3eComicDetailSummaryMetaRow(entry: entry),
        Md3eComicDetailPrimaryActions(
          onRead: onRead,
          onReadIncognito: onReadIncognito,
        ),
        Md3eComicDetailDescription(text: entry.description),
      ],
    );
  }
}
