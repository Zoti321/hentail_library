import 'package:flutter/material.dart';
import 'package:hentai_library/design-system/design_system.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

/// Virtualized Image set detail gallery as windowed rows.
///
/// Each cell owns its probed [AspectRatio] (plus affinity strip band), so row
/// height follows the tallest cell — fixed-extent [SliverGrid] cannot host
/// per-image aspects without cropping. Stable [ValueKey]s stay on the tiles.
class ImageSetRowGridSliver extends StatelessWidget {
  const ImageSetRowGridSliver({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
  });

  final int itemCount;
  final Widget Function(BuildContext context, int index) itemBuilder;

  @override
  Widget build(BuildContext context) {
    return SliverLayoutBuilder(
      builder: (BuildContext context, constraints) {
        final M3ESpacing spacing = M3ETheme.of(context).spacing;
        final CatalogGridLayout layout = CatalogGridMetrics.resolve(
          viewportWidth: constraints.crossAxisExtent,
          spacing: spacing,
          hasSubtitle: false,
        );
        final int columnCount = layout.crossAxisCount;
        final int rowCount = columnCount == 0
            ? 0
            : (itemCount + columnCount - 1) ~/ columnCount;

        return SliverPadding(
          padding: EdgeInsets.symmetric(horizontal: layout.horizontalMargin),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (BuildContext context, int rowIndex) {
                final int start = rowIndex * columnCount;
                final int end = (start + columnCount).clamp(0, itemCount);
                return Padding(
                  padding: EdgeInsets.only(
                    bottom: rowIndex < rowCount - 1 ? layout.gutter : 0,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      for (int slot = 0; slot < columnCount; slot++) ...<Widget>[
                        if (slot > 0) SizedBox(width: layout.gutter),
                        Expanded(
                          child: start + slot < end
                              ? itemBuilder(context, start + slot)
                              : const SizedBox.shrink(),
                        ),
                      ],
                    ],
                  ),
                );
              },
              childCount: rowCount,
              addAutomaticKeepAlives: false,
            ),
          ),
        );
      },
    );
  }
}
