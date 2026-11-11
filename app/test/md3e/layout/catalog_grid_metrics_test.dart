import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/design-system/design_system.dart';
import 'package:hentai_library/shared/ui/layout/catalog_grid_metrics.dart';

import '../../../widgetbook/lab/theme/md3e_theme.dart';

import 'package:material_3_expressive/material_3_expressive.dart';

void main() {
  test('catalog cell grows on large window classes', () {
    expect(
      CatalogGridMetrics.maxCrossAxisExtent(WindowSizeClass.compact),
      lessThan(
        CatalogGridMetrics.maxCrossAxisExtent(WindowSizeClass.extraLarge),
      ),
    );
  });

  test('crossAxisCount respects max cross axis extent', () {
    expect(
      CatalogGridMetrics.crossAxisCount(1200, WindowSizeClass.expanded),
      greaterThan(4),
    );
    expect(CatalogGridMetrics.crossAxisCount(400, WindowSizeClass.compact), 2);
  });

  test('resolve includes main axis extent from cell width', () {
    final M3ESpacing spacing = buildThemeData().spacing;
    final CatalogGridLayout layout = CatalogGridMetrics.resolve(
      viewportWidth: 800,
      spacing: spacing,
    );
    expect(layout.mainAxisExtent, greaterThan(layout.cellWidth));
  });

  test('layout cell width matches inner viewport', () {
    const double width = 360;
    final CatalogGridLayout layout = CatalogGridMetrics.layoutForViewportWidth(
      width,
    );
    final double inner = width - layout.horizontalMargin * 2;
    final double reconstructed =
        layout.cellWidth * layout.crossAxisCount +
        layout.gutter * (layout.crossAxisCount - 1);
    expect(reconstructed, closeTo(inner, 0.01));
  });
}
