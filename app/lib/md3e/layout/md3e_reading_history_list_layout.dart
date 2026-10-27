import 'package:flutter/material.dart';
import 'package:hentai_library/md3e/widgets/history/md3e_reading_history_list_item.dart';
import 'package:hentai_library/md3e/widgets/history/md3e_reading_history_list_item_metrics.dart';

/// Lays out [Md3eReadingHistoryListItem] children in 1–3 columns by viewport width.
class Md3eReadingHistoryListLayout extends StatelessWidget {
  const Md3eReadingHistoryListLayout({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.horizontalInset,
  });

  final int itemCount;
  final Widget Function(BuildContext context, int index) itemBuilder;
  final double? horizontalInset;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double viewportWidth = constraints.maxWidth;
        if (!constraints.hasBoundedWidth || viewportWidth <= 0) {
          return const SizedBox.shrink();
        }

        final Md3eReadingHistoryListLayoutSpec layout =
            Md3eReadingHistoryListItemMetrics.layoutForViewportWidth(
              viewportWidth,
              horizontalInset: horizontalInset,
            );

        if (layout.columnCount <= 1) {
          return Padding(
            padding: EdgeInsets.symmetric(horizontal: layout.horizontalInset),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                for (int index = 0; index < itemCount; index++) ...<Widget>[
                  if (index > 0) SizedBox(height: layout.gap),
                  itemBuilder(context, index),
                ],
              ],
            ),
          );
        }

        final List<Widget> rows = <Widget>[];
        for (int start = 0; start < itemCount; start += layout.columnCount) {
          final List<Widget> cells = <Widget>[];
          for (
            int column = 0;
            column < layout.columnCount && start + column < itemCount;
            column++
          ) {
            if (column > 0) {
              cells.add(SizedBox(width: layout.gap));
            }
            cells.add(
              SizedBox(
                width: layout.tileWidth,
                child: itemBuilder(context, start + column),
              ),
            );
          }
          if (rows.isNotEmpty) {
            rows.add(SizedBox(height: layout.gap));
          }
          rows.add(
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: cells,
            ),
          );
        }

        return Padding(
          padding: EdgeInsets.symmetric(horizontal: layout.horizontalInset),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: rows,
          ),
        );
      },
    );
  }
}
