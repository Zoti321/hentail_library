import 'package:flutter/material.dart';
import 'package:hentai_library/shared/ui/layout/page_layout_spec.dart';
import 'package:hentai_library/features/home/presentation/patterns/history/history_empty_body.dart';
import 'package:hentai_library/features/home/presentation/patterns/history/history_record_summary.dart';
import 'package:hentai_library/features/home/presentation/patterns/history/history_time_grouping.dart';
import 'package:hentai_library/features/home/presentation/patterns/history/reading_history_grouped_list.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

/// 阅读历史页滚动区正文：摘要 + 分组列表或空状态。
class Md3eHistoryBrowseContent<T> extends StatelessWidget {
  const Md3eHistoryBrowseContent({
    super.key,
    required this.totalCount,
    required this.groups,
    required this.itemBuilder,
    this.horizontalInset = 0,
    this.searchField,
    this.emptyMessage,
  });

  final int totalCount;
  final List<Md3eHistoryTimeGroup<T>> groups;
  final Widget Function(BuildContext context, T item) itemBuilder;
  final double horizontalInset;
  final Widget? searchField;
  final String? emptyMessage;

  @override
  Widget build(BuildContext context) {
    final Md3ePageLayoutSpec layout = Md3ePageLayoutSpec.of(context);
    final M3ESpacing spacing = M3ETheme.of(context).spacing;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Md3eHistoryRecordSummary(totalCount: totalCount),
        if (searchField != null) ...<Widget>[
          SizedBox(height: spacing.sm),
          searchField!,
        ],
        SizedBox(height: layout.headerToBodyGap),
        if (groups.isEmpty)
          Md3eHistoryEmptyBody(message: emptyMessage)
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
