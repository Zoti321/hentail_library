import 'package:flutter/material.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

/// 详情封面 + 主信息：窄屏单列、宽屏横排。
class Md3eComicDetailPrimaryRowLayout extends StatelessWidget {
  const Md3eComicDetailPrimaryRowLayout({
    super.key,
    required this.cover,
    required this.content,
    required this.coverWidth,
    this.rowGap,
    this.narrowBreakpoint = 600,
  });

  final Widget cover;
  final Widget content;
  final double coverWidth;
  final double? rowGap;
  final double narrowBreakpoint;

  @override
  Widget build(BuildContext context) {
    final M3ESpacing spacing = M3ETheme.of(context).spacing;
    final double gap = rowGap ?? spacing.xl;

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final bool narrow = constraints.maxWidth < narrowBreakpoint;
        final double resolvedCoverWidth = narrow
            ? coverWidth.clamp(0, constraints.maxWidth)
            : coverWidth;
        if (narrow) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Align(
                alignment: Alignment.center,
                child: SizedBox(width: resolvedCoverWidth, child: cover),
              ),
              SizedBox(height: gap),
              content,
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            SizedBox(width: resolvedCoverWidth, child: cover),
            SizedBox(width: gap),
            Expanded(child: content),
          ],
        );
      },
    );
  }
}
