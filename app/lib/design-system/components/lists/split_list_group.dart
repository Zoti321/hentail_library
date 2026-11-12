import 'package:flutter/material.dart';
import 'package:hentai_library/design-system/components/lists/split_list_row.dart';
import 'package:hentai_library/design-system/components/surfaces/tonal_surface.dart';

export 'package:hentai_library/design-system/components/lists/split_list_row.dart';

/// Stacked settings rows with outer 24dp radius and 4dp gutters.
class SplitListGroup extends StatelessWidget {
  const SplitListGroup({
    super.key,
    required this.children,
    this.outerRadius = kTonalSurfaceRadius,
  });

  final List<Widget> children;
  final double outerRadius;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        for (int i = 0; i < children.length; i++) ...<Widget>[
          if (i > 0) const SizedBox(height: kSplitListRowGap),
          SplitListRow(
            topRadius: i == 0 ? outerRadius : kSplitListInnerRadius,
            bottomRadius: i == children.length - 1
                ? outerRadius
                : kSplitListInnerRadius,
            pressedRadius: outerRadius,
            child: children[i],
          ),
        ],
      ],
    );
  }
}
