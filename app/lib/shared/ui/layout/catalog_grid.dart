import 'package:flutter/material.dart';
import 'package:hentai_library/shared/ui/layout/catalog_grid_metrics.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

/// Builds one catalog grid cell (index + resolved layout).
typedef CatalogGridItemBuilder = Widget Function(
  BuildContext context,
  int index,
  CatalogGridLayout layout,
);

/// [SliverGridDelegate] from a resolved [CatalogGridLayout].
SliverGridDelegate catalogGridDelegate(CatalogGridLayout layout) {
  return SliverGridDelegateWithFixedCrossAxisCount(
    crossAxisCount: layout.crossAxisCount,
    mainAxisExtent: layout.mainAxisExtent,
    crossAxisSpacing: layout.gutter,
    mainAxisSpacing: layout.gutter,
  );
}

/// Top-aligns a catalog card inside a grid cell (cross-axis stretch, no vertical centering).
class CatalogGridCell extends StatelessWidget {
  const CatalogGridCell({super.key, required this.child});

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
class CatalogGridSliver extends StatelessWidget {
  const CatalogGridSliver({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.horizontalMargin,
    this.hasSubtitle = true,
  });

  final int itemCount;
  final CatalogGridItemBuilder itemBuilder;
  final double? horizontalMargin;
  final bool hasSubtitle;

  @override
  Widget build(BuildContext context) {
    return SliverLayoutBuilder(
      builder: (BuildContext context, constraints) {
        final M3ESpacing spacing = M3ETheme.of(context).spacing;
        final CatalogGridLayout layout = CatalogGridMetrics.resolve(
          viewportWidth: constraints.crossAxisExtent,
          spacing: spacing,
          horizontalMargin: horizontalMargin,
          hasSubtitle: hasSubtitle,
        );

        return SliverPadding(
          padding: EdgeInsets.symmetric(horizontal: layout.horizontalMargin),
          sliver: SliverGrid(
            gridDelegate: catalogGridDelegate(layout),
            delegate: SliverChildBuilderDelegate((
              BuildContext context,
              int index,
            ) {
              return CatalogGridCell(
                child: itemBuilder(context, index, layout),
              );
            }, childCount: itemCount),
          ),
        );
      },
    );
  }
}
