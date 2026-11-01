import 'package:flutter/material.dart';
import 'package:hentai_library/shared/ui/layout/reading_history_list_layout.dart';
import 'package:hentai_library/shared/ui/motion/spring_size.dart';
import 'package:hentai_library/features/home/presentation/patterns/history/history_section_header.dart';
import 'package:hentai_library/features/home/presentation/patterns/history/history_time_grouping.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

/// 单个时间分桶：可折叠标题 + 组内响应式列表。
///
/// 展开 / 收起由 M3E 空间弹簧（[Md3eSpringSize]）驱动，与 M3E 展开列表同款手感。
class Md3eHistoryGroupSection<T> extends StatelessWidget {
  const Md3eHistoryGroupSection({
    super.key,
    required this.group,
    required this.expanded,
    required this.onHeaderPressed,
    required this.itemBuilder,
    this.horizontalInset,
  });

  final Md3eHistoryTimeGroup<T> group;
  final bool expanded;
  final VoidCallback onHeaderPressed;
  final Widget Function(BuildContext context, T item) itemBuilder;
  final double? horizontalInset;

  @override
  Widget build(BuildContext context) {
    final M3ESpacing spacing = M3ETheme.of(context).spacing;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Md3eHistorySectionHeader(
          section: group.section,
          itemCount: group.items.length,
          expanded: expanded,
          onPressed: onHeaderPressed,
        ),
        Md3eSpringSize(
          expanded: expanded,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              SizedBox(height: spacing.xs),
              Md3eReadingHistoryListLayout(
                itemCount: group.items.length,
                horizontalInset: horizontalInset,
                itemBuilder: (BuildContext context, int index) {
                  return itemBuilder(context, group.items[index]);
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}
