import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:hentai_library/features/reading_history/presentation/patterns/history/reading_history_list_row.dart';
import 'package:hentai_library/features/reading_history/presentation/widgets/reading_history_list_item_metrics.dart';

export 'package:hentai_library/features/reading_history/presentation/patterns/history/reading_history_list_row.dart';

/// 默认与 [RenderViewport.defaultCacheExtent] 对齐的预构建边距。
const double _kHistoryGridCacheExtent = 250;
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

class ReadingHistoryVirtualizedRows extends StatefulWidget {
  const ReadingHistoryVirtualizedRows({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    required this.layout,
  });

  final int itemCount;
  final Widget Function(BuildContext context, int index) itemBuilder;
  final ReadingHistoryListLayoutSpec layout;

  @override
  State<ReadingHistoryVirtualizedRows> createState() =>
      ReadingHistoryVirtualizedRowsState();
}

class ReadingHistoryVirtualizedRowsState
    extends State<ReadingHistoryVirtualizedRows> {
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
  void didUpdateWidget(covariant ReadingHistoryVirtualizedRows oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.itemCount != widget.itemCount ||
        oldWidget.layout.columnCount != widget.layout.columnCount ||
        oldWidget.layout.gap != widget.layout.gap ||
        oldWidget.layout.itemSpec.rowHeight !=
            widget.layout.itemSpec.rowHeight) {
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
      final RenderObject? viewportRender = scrollable.context
          .findRenderObject();
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
              child: ReadingHistoryListRow(
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
