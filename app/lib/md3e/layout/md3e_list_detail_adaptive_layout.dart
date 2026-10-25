import 'package:flutter/material.dart';

/// M3-style expanded breakpoint (840dp): list+detail side-by-side at or above it.
const double kMd3eListDetailExpandedBreakpoint = 840;

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
    this.listPaneKey,
    this.detailPaneKey,
  });

  final Widget listPane;
  final Widget detailPane;
  final double expandedBreakpoint;
  final bool showDetailOnCompact;
  final Key? listPaneKey;
  final Key? detailPaneKey;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final bool expanded = constraints.maxWidth >= expandedBreakpoint;
        if (expanded) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Expanded(
                key: listPaneKey,
                flex: 2,
                child: listPane,
              ),
              const VerticalDivider(width: 1),
              Expanded(
                key: detailPaneKey,
                flex: 3,
                child: detailPane,
              ),
            ],
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
