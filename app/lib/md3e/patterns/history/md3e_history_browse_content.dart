import 'package:flutter/material.dart';
import 'package:hentai_library/md3e/layout/md3e_breakpoints.dart';
import 'package:hentai_library/md3e/layout/md3e_library_browse_page_metrics.dart';
import 'package:hentai_library/md3e/patterns/history/md3e_history_empty_body.dart';
import 'package:hentai_library/md3e/patterns/history/md3e_history_record_summary.dart';
import 'package:hentai_library/md3e/patterns/history/md3e_history_time_grouping.dart';
import 'package:hentai_library/md3e/patterns/history/md3e_reading_history_grouped_list.dart';

/// 阅读历史页滚动区正文：摘要 + 分组列表或空状态。
class Md3eHistoryBrowseContent<T> extends StatelessWidget {
  const Md3eHistoryBrowseContent({
    super.key,
    required this.totalCount,
    required this.groups,
    required this.itemBuilder,
    this.horizontalInset = 0,
  });

  final int totalCount;
  final List<Md3eHistoryTimeGroup<T>> groups;
  final Widget Function(BuildContext context, T item) itemBuilder;
  final double horizontalInset;

  @override
  Widget build(BuildContext context) {
    final Md3eWindowSizeClass sizeClass = md3eWindowSizeClassOf(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Md3eHistoryRecordSummary(totalCount: totalCount),
        SizedBox(
          height: Md3eLibraryBrowsePageMetrics.catalogBodyTopSpacing(sizeClass),
        ),
        if (groups.isEmpty)
          const Md3eHistoryEmptyBody()
        else
          Md3eReadingHistoryGroupedList<T>(
            groups: groups,
            horizontalInset: horizontalInset,
            itemBuilder: itemBuilder,
          ),
      ],
    );
  }
}
