import 'package:flutter/material.dart';
import 'package:hentai_library/features/home/presentation/patterns/history/history_group_section.dart';
import 'package:hentai_library/features/home/presentation/patterns/history/history_time_grouping.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

/// 四档时间分组 + 可折叠组标题 + 组内 [Md3eReadingHistoryListLayout]。
class Md3eReadingHistoryGroupedList<T> extends StatefulWidget {
  const Md3eReadingHistoryGroupedList({
    super.key,
    required this.groups,
    required this.itemBuilder,
    this.horizontalInset,
  });

  final List<Md3eHistoryTimeGroup<T>> groups;
  final Widget Function(BuildContext context, T item) itemBuilder;
  final double? horizontalInset;

  @override
  State<Md3eReadingHistoryGroupedList<T>> createState() =>
      _Md3eReadingHistoryGroupedListState<T>();
}

class _Md3eReadingHistoryGroupedListState<T>
    extends State<Md3eReadingHistoryGroupedList<T>> {
  final Set<Md3eHistoryTimeSection> _collapsed = <Md3eHistoryTimeSection>{};

  bool _isExpanded(Md3eHistoryTimeSection section) {
    return !_collapsed.contains(section);
  }

  void _toggle(Md3eHistoryTimeSection section) {
    setState(() {
      if (_collapsed.contains(section)) {
        _collapsed.remove(section);
      } else {
        _collapsed.add(section);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final M3ESpacing spacing = M3ETheme.of(context).spacing;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        for (int index = 0; index < widget.groups.length; index++) ...<Widget>[
          if (index > 0) SizedBox(height: spacing.md),
          Md3eHistoryGroupSection<T>(
            group: widget.groups[index],
            expanded: _isExpanded(widget.groups[index].section),
            onHeaderPressed: () => _toggle(widget.groups[index].section),
            itemBuilder: widget.itemBuilder,
            horizontalInset: widget.horizontalInset,
          ),
        ],
      ],
    );
  }
}
