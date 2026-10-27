import 'package:flutter/material.dart';
import 'package:hentai_library/md3e/layout/md3e_reading_history_list_layout.dart';
import 'package:hentai_library/md3e/patterns/history/md3e_history_section_header.dart';
import 'package:hentai_library/md3e/patterns/history/md3e_history_time_grouping.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

/// 单个时间分桶：可折叠标题 + 组内响应式列表。
class Md3eHistoryGroupSection<T> extends StatelessWidget {
  const Md3eHistoryGroupSection({
    super.key,
    required this.group,
    required this.expanded,
    required this.onHeaderPressed,
    required this.itemBuilder,
    required this.duration,
    required this.curve,
    this.horizontalInset,
  });

  final Md3eHistoryTimeGroup<T> group;
  final bool expanded;
  final VoidCallback onHeaderPressed;
  final Widget Function(BuildContext context, T item) itemBuilder;
  final Duration duration;
  final Curve curve;
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
        AnimatedCrossFade(
          firstChild: Column(
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
          secondChild: const SizedBox.shrink(),
          crossFadeState: expanded
              ? CrossFadeState.showFirst
              : CrossFadeState.showSecond,
          duration: duration,
          sizeCurve: curve,
        ),
      ],
    );
  }
}
