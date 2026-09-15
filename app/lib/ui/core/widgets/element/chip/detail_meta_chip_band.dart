import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hentai_library/ui/core/layout/detail_meta_chip_band_layout.dart';
import 'package:hentai_library/ui/core/layout/detail_meta_chip_row_layout.dart';
import 'package:hentai_library/ui/core/theme/theme.dart';
import 'package:hentai_library/ui/core/widgets/foundation/horizontal_wheel_scroll_listener.dart';

/// Shared detail facet chip band: wrap up to [maxRows], then horizontal scroll.
///
/// Empty [children] renders nothing (no reserved height). Underfull bands size
/// to used rows only; overfull bands lock to the row cap and scroll as a whole.
class DetailMetaChipBand extends HookWidget {
  const DetailMetaChipBand({
    super.key,
    required this.children,
    required this.maxRows,
    this.rowHeight = kDetailMetaChipRowHeight,
  });

  final List<Widget> children;
  final int maxRows;
  final double rowHeight;

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) {
      return const SizedBox.shrink();
    }
    final AppThemeTokens tokens = context.tokens;
    final ScrollController scrollController = useScrollController();
    final double spacing = tokens.spacing.sm;
    final double runSpacing = tokens.spacing.sm;

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double availableWidth = constraints.maxWidth;
        return HorizontalWheelScrollListener(
          controller: scrollController,
          child: SingleChildScrollView(
            controller: scrollController,
            scrollDirection: Axis.horizontal,
            child: _DetailMetaChipBandPanel(
              availableWidth: availableWidth,
              maxRows: maxRows,
              spacing: spacing,
              runSpacing: runSpacing,
              rowHeight: rowHeight,
              children: children,
            ),
          ),
        );
      },
    );
  }
}

class _DetailMetaChipBandPanel extends MultiChildRenderObjectWidget {
  const _DetailMetaChipBandPanel({
    required this.availableWidth,
    required this.maxRows,
    required this.spacing,
    required this.runSpacing,
    required this.rowHeight,
    required super.children,
  });

  final double availableWidth;
  final int maxRows;
  final double spacing;
  final double runSpacing;
  final double rowHeight;

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _RenderDetailMetaChipBandPanel(
      availableWidth: availableWidth,
      maxRows: maxRows,
      spacing: spacing,
      runSpacing: runSpacing,
      rowHeight: rowHeight,
    );
  }

  @override
  void updateRenderObject(
    BuildContext context,
    covariant _RenderDetailMetaChipBandPanel renderObject,
  ) {
    renderObject
      ..availableWidth = availableWidth
      ..maxRows = maxRows
      ..spacing = spacing
      ..runSpacing = runSpacing
      ..rowHeight = rowHeight;
  }
}

class _DetailMetaChipBandParentData extends ContainerBoxParentData<RenderBox> {}

class _RenderDetailMetaChipBandPanel extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, _DetailMetaChipBandParentData>,
        RenderBoxContainerDefaultsMixin<
          RenderBox,
          _DetailMetaChipBandParentData
        > {
  _RenderDetailMetaChipBandPanel({
    required double availableWidth,
    required int maxRows,
    required double spacing,
    required double runSpacing,
    required double rowHeight,
  }) : _availableWidth = availableWidth,
       _maxRows = maxRows,
       _spacing = spacing,
       _runSpacing = runSpacing,
       _rowHeight = rowHeight;

  double _availableWidth;
  double get availableWidth => _availableWidth;
  set availableWidth(double value) {
    if (_availableWidth == value) {
      return;
    }
    _availableWidth = value;
    markNeedsLayout();
  }

  int _maxRows;
  int get maxRows => _maxRows;
  set maxRows(int value) {
    if (_maxRows == value) {
      return;
    }
    _maxRows = value;
    markNeedsLayout();
  }

  double _spacing;
  double get spacing => _spacing;
  set spacing(double value) {
    if (_spacing == value) {
      return;
    }
    _spacing = value;
    markNeedsLayout();
  }

  double _runSpacing;
  double get runSpacing => _runSpacing;
  set runSpacing(double value) {
    if (_runSpacing == value) {
      return;
    }
    _runSpacing = value;
    markNeedsLayout();
  }

  double _rowHeight;
  double get rowHeight => _rowHeight;
  set rowHeight(double value) {
    if (_rowHeight == value) {
      return;
    }
    _rowHeight = value;
    markNeedsLayout();
  }

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! _DetailMetaChipBandParentData) {
      child.parentData = _DetailMetaChipBandParentData();
    }
  }

  @override
  void performLayout() {
    final List<RenderBox> kids = <RenderBox>[];
    final List<double> widths = <double>[];
    RenderBox? child = firstChild;
    while (child != null) {
      child.layout(BoxConstraints(maxHeight: _rowHeight), parentUsesSize: true);
      kids.add(child);
      widths.add(child.size.width);
      child = childAfter(child);
    }

    final DetailMetaChipBandLayout layout = layoutDetailMetaChipBand(
      chipWidths: widths,
      availableWidth: _availableWidth,
      maxRows: _maxRows,
      spacing: _spacing,
      runSpacing: _runSpacing,
      rowHeight: _rowHeight,
    );

    var x = 0.0;
    var y = 0.0;
    for (var i = 0; i < kids.length; i++) {
      final double w = widths[i];
      final _DetailMetaChipBandParentData parentData =
          kids[i].parentData! as _DetailMetaChipBandParentData;
      if (x == 0) {
        parentData.offset = Offset(0, y);
        x = w;
      } else if (x + _spacing + w <= layout.contentWidth + 1e-6) {
        parentData.offset = Offset(x + _spacing, y);
        x += _spacing + w;
      } else {
        y += _rowHeight + _runSpacing;
        parentData.offset = Offset(0, y);
        x = w;
      }
    }

    size = constraints.constrain(Size(layout.contentWidth, layout.bandHeight));
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    return defaultHitTestChildren(result, position: position);
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    defaultPaint(context, offset);
  }

  @override
  double? computeDistanceToActualBaseline(TextBaseline baseline) {
    return defaultComputeDistanceToHighestActualBaseline(baseline);
  }
}
