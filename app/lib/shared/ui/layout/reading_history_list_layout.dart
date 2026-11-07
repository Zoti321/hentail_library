import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:hentai_library/shared/ui/widgets/history/reading_history_list_item_metrics.dart';

/// 阅读历史卡片网格（盒模型）：按宽度决定 1–3 列，整组一次构建。
///
/// 用于时间分组 [SpringSize] 折叠动画；水平留白由外层负责。
class ReadingHistoryListGrid extends StatelessWidget {
  const ReadingHistoryListGrid({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
  });

  final int itemCount;
  final Widget Function(BuildContext context, int index) itemBuilder;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double viewportWidth = constraints.maxWidth;
        if (viewportWidth <= 0 || itemCount <= 0) {
          return const SizedBox.shrink();
        }

        final ReadingHistoryListLayoutSpec layout =
            ReadingHistoryListItemMetrics.layoutForViewportWidth(
              viewportWidth,
              horizontalInset: 0,
            );
        return _ReadingHistoryListRows(
          itemCount: itemCount,
          itemBuilder: itemBuilder,
          layout: layout,
        );
      },
    );
  }
}

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
            return _ReadingHistoryListRow(
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

class _ReadingHistoryListRows extends StatelessWidget {
  const _ReadingHistoryListRows({
    required this.itemCount,
    required this.itemBuilder,
    required this.layout,
  });

  final int itemCount;
  final Widget Function(BuildContext context, int index) itemBuilder;
  final ReadingHistoryListLayoutSpec layout;

  @override
  Widget build(BuildContext context) {
    final int columns = layout.columnCount;
    final int rowCount = (itemCount + columns - 1) ~/ columns;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        for (int row = 0; row < rowCount; row++)
          _ReadingHistoryListRow(
            row: row,
            rowCount: rowCount,
            itemCount: itemCount,
            itemBuilder: itemBuilder,
            layout: layout,
          ),
      ],
    );
  }
}

class _ReadingHistoryListRow extends StatelessWidget {
  const _ReadingHistoryListRow({
    required this.row,
    required this.rowCount,
    required this.itemCount,
    required this.itemBuilder,
    required this.layout,
  });

  final int row;
  final int rowCount;
  final int itemCount;
  final Widget Function(BuildContext context, int index) itemBuilder;
  final ReadingHistoryListLayoutSpec layout;

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
      cells.add(
        SizedBox(
          width: layout.tileWidth,
          child: itemBuilder(context, start + column),
        ),
      );
    }
    final bool isLastRow = row == rowCount - 1;
    return Padding(
      padding: EdgeInsets.only(bottom: isLastRow ? 0 : layout.gap),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: cells,
      ),
    );
  }
}
