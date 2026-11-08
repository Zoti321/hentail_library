import 'package:flutter/material.dart';
import 'package:hentai_library/shared/ui/layout/page_layout_spec.dart';
import 'package:hentai_library/features/reading_history/presentation/patterns/history/history_empty_body.dart';
import 'package:hentai_library/features/reading_history/presentation/patterns/history/history_record_summary.dart';
import 'package:hentai_library/features/reading_history/presentation/patterns/history/history_time_grouping.dart';
import 'package:hentai_library/features/reading_history/presentation/patterns/history/history_grouped_list.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

/// 阅读历史页滚动区正文（sliver）：摘要 + 搜索 + 分组列表或空状态。
///
/// 需放在 `SliverPadding` 内以获得水平留白；分组列表在
/// `SpringExpandPanel` 内用盒模型网格，组内按行虚拟化构建。
class HistoryBrowseContent<T> extends StatelessWidget {
  const HistoryBrowseContent({
    super.key,
    required this.totalCount,
    required this.groups,
    required this.itemBuilder,
    this.searchField,
    this.emptyMessage,
  });

  final int totalCount;
  final List<HistoryTimeGroup<T>> groups;
  final Widget Function(BuildContext context, T item) itemBuilder;
  final Widget? searchField;
  final String? emptyMessage;

  @override
  Widget build(BuildContext context) {
    final PageLayoutSpec layout = PageLayoutSpec.of(context);
    final M3ESpacing spacing = M3ETheme.of(context).spacing;

    return SliverMainAxisGroup(
      slivers: <Widget>[
        SliverToBoxAdapter(child: HistoryRecordSummary(totalCount: totalCount)),
        if (searchField != null) ...<Widget>[
          SliverToBoxAdapter(child: SizedBox(height: spacing.sm)),
          SliverToBoxAdapter(child: searchField!),
        ],
        SliverToBoxAdapter(child: SizedBox(height: layout.headerToBodyGap)),
        if (groups.isEmpty)
          SliverToBoxAdapter(child: HistoryEmptyBody(message: emptyMessage))
        else
          ReadingHistoryGroupedList<T>(
            groups: groups,
            itemBuilder: itemBuilder,
          ),
      ],
    );
  }
}
