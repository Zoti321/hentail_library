import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:hentai_library/features/reading_history/presentation/patterns/history/reading_history_virtualized_rows.dart';
import 'package:hentai_library/features/reading_history/presentation/widgets/reading_history_list_item_metrics.dart';

/// 阅读历史列表（sliver）：按视口宽度决定 1–3 列，按行懒构建。
///
/// 水平留白由外层 `SliverPadding` 负责，这里只用 crossAxisExtent 计算列宽；
/// 只有进入视口（含 cacheExtent）的行会被构建，因此封面请求也只发生在可见区域。
class ReadingHistoryListLayout extends StatelessWidget {
  const ReadingHistoryListLayout({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
  });

  final int itemCount;
  final Widget Function(BuildContext context, int index) itemBuilder;

  @override
  Widget build(BuildContext context) {
    return SliverLayoutBuilder(
      builder: (BuildContext context, SliverConstraints constraints) {
        final double viewportWidth = constraints.crossAxisExtent;
        if (viewportWidth <= 0 || itemCount <= 0) {
          return const SliverToBoxAdapter(child: SizedBox.shrink());
        }

        final ReadingHistoryListLayoutSpec layout =
            ReadingHistoryListItemMetrics.layoutForViewportWidth(
              viewportWidth,
              horizontalInset: 0,
            );
        final int columns = layout.columnCount;
        final int rowCount = (itemCount + columns - 1) ~/ columns;

        return SliverList.builder(
          itemCount: rowCount,
          itemBuilder: (BuildContext context, int row) {
            return ReadingHistoryListRow(
              key: ValueKey<int>(row),
              row: row,
              rowCount: rowCount,
              itemCount: itemCount,
              itemBuilder: itemBuilder,
              layout: layout,
            );
          },
        );
      },
    );
  }
}
