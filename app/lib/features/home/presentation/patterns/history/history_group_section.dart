import 'package:flutter/material.dart';
import 'package:hentai_library/shared/ui/layout/reading_history_list_layout.dart';
import 'package:hentai_library/features/home/presentation/patterns/history/history_section_header.dart';
import 'package:hentai_library/features/home/presentation/patterns/history/history_time_grouping.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

/// 单个时间分桶（sliver）：可折叠标题 + 组内懒加载的 [Md3eReadingHistoryListLayout]。
///
/// 折叠时不构建组内任何行，因此折叠组不占用构建与封面加载成本。
class Md3eHistoryGroupSection<T> extends StatelessWidget {
  const Md3eHistoryGroupSection({
    super.key,
    required this.group,
    required this.expanded,
    required this.onHeaderPressed,
    required this.itemBuilder,
  });

  final Md3eHistoryTimeGroup<T> group;
  final bool expanded;
  final VoidCallback onHeaderPressed;
  final Widget Function(BuildContext context, T item) itemBuilder;

  @override
  Widget build(BuildContext context) {
    final M3ESpacing spacing = M3ETheme.of(context).spacing;

    return SliverMainAxisGroup(
      slivers: <Widget>[
        SliverToBoxAdapter(
          child: Md3eHistorySectionHeader(
            section: group.section,
            itemCount: group.items.length,
            expanded: expanded,
            onPressed: onHeaderPressed,
          ),
        ),
        if (expanded) ...<Widget>[
          SliverToBoxAdapter(child: SizedBox(height: spacing.xs)),
          Md3eReadingHistoryListLayout(
            itemCount: group.items.length,
            itemBuilder: (BuildContext context, int index) {
              return itemBuilder(context, group.items[index]);
            },
          ),
        ],
      ],
    );
  }
}
