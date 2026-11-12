import 'package:flutter/material.dart';
import 'package:hentai_library/shared/ui/layout/catalog_grid_metrics.dart';

export 'package:hentai_library/shared/ui/layout/catalog_grid_box.dart';
export 'package:hentai_library/shared/ui/layout/catalog_grid_sliver.dart';

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
