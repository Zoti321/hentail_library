import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:hentai_library/shared/ui/widgets/history/reading_history_list_item_metrics.dart';

/// 默认与 [RenderViewport.defaultCacheExtent] 对齐的预构建边距。
const double _kHistoryGridCacheExtent = 250;

/// 阅读历史卡片网格（盒模型）：按宽度决定 1–3 列，**固定行高虚拟化**。
///
/// 对外以公式给出整组高度，供时间分组 [SpringExpandPanel] 的 `heightFactor`
/// 动画量测；对内只挂载落入外层 [Scrollable] 可见区（含 cache）的行，
/// 避免大桶展开时一次性创建全部卡片 Element。
///
/// 水平留白由外层负责。
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
        return _VirtualizedReadingHistoryListRows(
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

@visibleForTesting
double readingHistoryGridTotalHeight({
  required int itemCount,
  required ReadingHistoryListLayoutSpec layout,
}) {
  if (itemCount <= 0) {
    return 0;
  }
  final int columns = layout.columnCount;
  final int rowCount = (itemCount + columns - 1) ~/ columns;
  final double rowHeight = layout.itemSpec.rowHeight;
  final double gap = layout.gap;
  return rowCount * rowHeight + math.max(0, rowCount - 1) * gap;
}

class _VirtualizedReadingHistoryListRows extends StatefulWidget {
  const _VirtualizedReadingHistoryListRows({
    required this.itemCount,
    required this.itemBuilder,
    required this.layout,
  });

  final int itemCount;
  final Widget Function(BuildContext context, int index) itemBuilder;
  final ReadingHistoryListLayoutSpec layout;

  @override
  State<_VirtualizedReadingHistoryListRows> createState() =>
      _VirtualizedReadingHistoryListRowsState();
}

class _VirtualizedReadingHistoryListRowsState
    extends State<_VirtualizedReadingHistoryListRows> {
  ScrollPosition? _position;
  int _firstRow = 0;
  int _lastRow = 0;
  bool _windowInitialized = false;
  bool _checkScheduled = false;

  int get _columns => widget.layout.columnCount;

  int get _rowCount {
    if (widget.itemCount <= 0) {
      return 0;
    }
    return (widget.itemCount + _columns - 1) ~/ _columns;
  }

  double get _rowHeight => widget.layout.itemSpec.rowHeight;

  double get _gap => widget.layout.gap;

  double get _stride => _rowHeight + _gap;

  double get _totalHeight => readingHistoryGridTotalHeight(
    itemCount: widget.itemCount,
    layout: widget.layout,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _attachScrollable();
    _scheduleVisibleWindowUpdate();
  }

  @override
  void didUpdateWidget(covariant _VirtualizedReadingHistoryListRows oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.itemCount != widget.itemCount ||
        oldWidget.layout.columnCount != widget.layout.columnCount ||
        oldWidget.layout.gap != widget.layout.gap ||
        oldWidget.layout.itemSpec.rowHeight != widget.layout.itemSpec.rowHeight) {
      _scheduleVisibleWindowUpdate();
    }
  }

  @override
  void dispose() {
    _detachScrollable();
    super.dispose();
  }

  void _attachScrollable() {
    final ScrollPosition? next = Scrollable.maybeOf(context)?.position;
    if (identical(next, _position)) {
      return;
    }
    _detachScrollable();
    _position = next;
    _position?.addListener(_scheduleVisibleWindowUpdate);
    _position?.isScrollingNotifier.addListener(_scheduleVisibleWindowUpdate);
  }

  void _detachScrollable() {
    _position?.removeListener(_scheduleVisibleWindowUpdate);
    _position?.isScrollingNotifier.removeListener(_scheduleVisibleWindowUpdate);
    _position = null;
  }

  void _scheduleVisibleWindowUpdate() {
    if (_checkScheduled) {
      return;
    }
    _checkScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkScheduled = false;
      if (!mounted) {
        return;
      }
      _updateVisibleWindow();
    });
  }

  int _estimateLastRow() {
    final int rowCount = _rowCount;
    if (rowCount <= 0) {
      return 0;
    }
    final double viewportH = MediaQuery.sizeOf(context).height;
    final int estimated =
        (viewportH / math.max(_stride, 1)).ceil() +
        (_kHistoryGridCacheExtent / math.max(_stride, 1)).ceil() +
        1;
    return math.min(rowCount - 1, math.max(0, estimated));
  }

  int _rowIndexForY(double y) {
    final int rowCount = _rowCount;
    if (rowCount <= 0) {
      return 0;
    }
    if (y <= 0) {
      return 0;
    }
    final double total = _totalHeight;
    if (y >= total) {
      return rowCount - 1;
    }
    return (y / _stride).floor().clamp(0, rowCount - 1);
  }

  void _updateVisibleWindow() {
    final int rowCount = _rowCount;
    if (rowCount <= 0) {
      if (_windowInitialized && (_firstRow != 0 || _lastRow != 0)) {
        setState(() {
          _firstRow = 0;
          _lastRow = 0;
        });
      }
      return;
    }

    int first;
    int last;

    final RenderObject? renderObject = context.findRenderObject();
    final ScrollableState? scrollable = Scrollable.maybeOf(context);
    if (renderObject is! RenderBox || !renderObject.hasSize) {
      first = 0;
      last = _estimateLastRow();
    } else if (scrollable == null) {
      first = 0;
      last = _estimateLastRow();
    } else {
      final RenderObject? viewportRender = scrollable.context.findRenderObject();
      if (viewportRender is! RenderBox || !viewportRender.hasSize) {
        first = 0;
        last = _estimateLastRow();
      } else {
        final Offset topLeft = renderObject.localToGlobal(
          Offset.zero,
          ancestor: viewportRender,
        );
        final double cache = _kHistoryGridCacheExtent;
        final double visibleTop = -topLeft.dy - cache;
        final double visibleBottom =
            viewportRender.size.height - topLeft.dy + cache;
        final double total = _totalHeight;
        first = _rowIndexForY(visibleTop.clamp(0.0, total));
        last = _rowIndexForY(
          math.max(0.0, visibleBottom - 0.001).clamp(0.0, total),
        );
        if (last < first) {
          last = first;
        }
      }
    }

    first = first.clamp(0, rowCount - 1);
    last = last.clamp(0, rowCount - 1);

    if (!_windowInitialized || first != _firstRow || last != _lastRow) {
      setState(() {
        _firstRow = first;
        _lastRow = last;
        _windowInitialized = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final int rowCount = _rowCount;
    if (rowCount <= 0) {
      return const SizedBox.shrink();
    }

    final int first = _windowInitialized ? _firstRow : 0;
    final int last = _windowInitialized ? _lastRow : _estimateLastRow();

    return SizedBox(
      height: _totalHeight,
      width: double.infinity,
      child: Stack(
        clipBehavior: Clip.none,
        children: <Widget>[
          for (int row = first; row <= last; row++)
            Positioned(
              key: ValueKey<int>(row),
              top: row * _stride,
              left: 0,
              right: 0,
              height: _rowHeight,
              child: _ReadingHistoryListRow(
                row: row,
                rowCount: rowCount,
                itemCount: widget.itemCount,
                itemBuilder: widget.itemBuilder,
                layout: widget.layout,
                includeBottomGap: false,
              ),
            ),
        ],
      ),
    );
  }
}

class _ReadingHistoryListRow extends StatelessWidget {
  const _ReadingHistoryListRow({
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
