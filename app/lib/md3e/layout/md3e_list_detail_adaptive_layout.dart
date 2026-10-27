import 'package:flutter/material.dart';

import 'md3e_breakpoints.dart';

/// List+detail side-by-side at [Md3eWindowSizeClass.expanded] and wider (≥840dp).
const double kMd3eListDetailExpandedBreakpoint = Md3eBreakpoints.expanded;

/// Responsive list–detail shell for MD3E Lab (not production App Shell).
///
/// Expanded: list and detail panes together. Compact: list only, or full-screen
/// detail when [showDetailOnCompact] is true (e.g. after navigation).
class Md3eListDetailAdaptiveLayout extends StatelessWidget {
  const Md3eListDetailAdaptiveLayout({
    super.key,
    required this.listPane,
    required this.detailPane,
    this.expandedBreakpoint = kMd3eListDetailExpandedBreakpoint,
    this.showDetailOnCompact = false,
    this.showPaneDivider = true,
    this.listPaneFixedWidth,
    this.paneGap = 0,
    this.listPaneKey,
    this.detailPaneKey,
  });

  final Widget listPane;
  final Widget detailPane;
  final double expandedBreakpoint;
  final bool showDetailOnCompact;

  /// When false, list and detail share one surface (e.g. settings).
  final bool showPaneDivider;

  /// When set at expanded width, list uses this width instead of flex 2:3.
  final double? listPaneFixedWidth;

  /// Horizontal gap between panes when [listPaneFixedWidth] is set.
  final double paneGap;

  final Key? listPaneKey;
  final Key? detailPaneKey;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final bool expanded = constraints.maxWidth >= expandedBreakpoint;
        if (expanded) {
          final List<Widget> rowChildren = <Widget>[
            if (listPaneFixedWidth != null)
              SizedBox(
                key: listPaneKey,
                width: listPaneFixedWidth,
                child: listPane,
              )
            else
              Expanded(
                key: listPaneKey,
                flex: 2,
                child: listPane,
              ),
            if (paneGap > 0) SizedBox(width: paneGap),
            if (showPaneDivider && listPaneFixedWidth == null)
              const VerticalDivider(width: 1),
            Expanded(
              key: detailPaneKey,
              flex: listPaneFixedWidth != null ? 1 : 3,
              child: detailPane,
            ),
          ];
          return Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: rowChildren,
          );
        }
        if (showDetailOnCompact) {
          return KeyedSubtree(key: detailPaneKey, child: detailPane);
        }
        return KeyedSubtree(key: listPaneKey, child: listPane);
      },
    );
  }
}
