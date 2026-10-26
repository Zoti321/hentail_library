import 'package:flutter/material.dart';
import 'package:hentai_library/md3e/layout/md3e_catalog_grid_metrics.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

/// Builds one catalog grid cell (index + resolved layout).
typedef Md3eCatalogGridItemBuilder = Widget Function(
  BuildContext context,
  int index,
  Md3eCatalogGridLayout layout,
);

/// [SliverGridDelegate] from a resolved [Md3eCatalogGridLayout].
SliverGridDelegate md3eCatalogGridDelegate(Md3eCatalogGridLayout layout) {
  return SliverGridDelegateWithFixedCrossAxisCount(
    crossAxisCount: layout.crossAxisCount,
    mainAxisExtent: layout.mainAxisExtent,
    crossAxisSpacing: layout.gutter,
    mainAxisSpacing: layout.gutter,
  );
}

/// Top-aligns a catalog card inside a grid cell (cross-axis stretch, no vertical centering).
class Md3eCatalogGridCell extends StatelessWidget {
  const Md3eCatalogGridCell({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      widthFactor: 1,
      heightFactor: 1,
      child: child,
    );
  }
}

/// Responsive comic catalog grid: margins, column count, gutters, and row height
/// are computed in the layout layer; children only fill the cell.
class Md3eCatalogGridSliver extends StatelessWidget {
  const Md3eCatalogGridSliver({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.horizontalMargin,
    this.hasSubtitle = true,
  });

  final int itemCount;
  final Md3eCatalogGridItemBuilder itemBuilder;
  final double? horizontalMargin;
  final bool hasSubtitle;

  @override
  Widget build(BuildContext context) {
    return SliverLayoutBuilder(
      builder: (BuildContext context, constraints) {
        final M3ESpacing spacing = M3ETheme.of(context).spacing;
        final Md3eCatalogGridLayout layout =
            Md3eCatalogGridMetrics.resolve(
          viewportWidth: constraints.crossAxisExtent,
          spacing: spacing,
          horizontalMargin: horizontalMargin,
          hasSubtitle: hasSubtitle,
        );

        return SliverPadding(
          padding: EdgeInsets.symmetric(horizontal: layout.horizontalMargin),
          sliver: SliverGrid(
            gridDelegate: md3eCatalogGridDelegate(layout),
            delegate: SliverChildBuilderDelegate(
              (BuildContext context, int index) {
                return Md3eCatalogGridCell(
                  child: itemBuilder(context, index, layout),
                );
              },
              childCount: itemCount,
            ),
          ),
        );
      },
    );
  }
}
