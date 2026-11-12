import 'package:flutter/material.dart';
import 'package:hentai_library/features/reading_history/presentation/widgets/reading_history_list_item_metrics.dart';

class ReadingHistoryListRow extends StatelessWidget {
  const ReadingHistoryListRow({
    super.key,
    required this.row,
    required this.rowCount,
    required this.itemCount,
    required this.itemBuilder,
    required this.layout,
    this.includeBottomGap = true,
  });

  final int row;
  final int rowCount;
  final int itemCount;
  final Widget Function(BuildContext context, int index) itemBuilder;
  final ReadingHistoryListLayoutSpec layout;
  final bool includeBottomGap;

  @override
  Widget build(BuildContext context) {
    final int columns = layout.columnCount;
    final int start = row * columns;
    final List<Widget> cells = <Widget>[];
    for (
      int column = 0;
      column < columns && start + column < itemCount;
      column++
    ) {
      if (column > 0) {
        cells.add(SizedBox(width: layout.gap));
      }
      final int itemIndex = start + column;
      cells.add(
        SizedBox(
          width: layout.tileWidth,
          child: KeyedSubtree(
            key: ValueKey<int>(itemIndex),
            child: itemBuilder(context, itemIndex),
          ),
        ),
      );
    }
    final Widget rowChild = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: cells,
    );
    if (!includeBottomGap) {
      return rowChild;
    }
    final bool isLastRow = row == rowCount - 1;
    return Padding(
      padding: EdgeInsets.only(bottom: isLastRow ? 0 : layout.gap),
      child: rowChild,
    );
  }
}
