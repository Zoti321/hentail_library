import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/md3e/layout/md3e_breakpoints.dart';
import 'package:hentai_library/md3e/layout/md3e_catalog_grid_metrics.dart';
import 'package:hentai_library/md3e/theme/md3e_theme.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

void main() {
  test('catalog cell grows on large window classes', () {
    expect(
      Md3eCatalogGridMetrics.maxCrossAxisExtent(
        Md3eWindowSizeClass.compact,
      ),
      lessThan(
        Md3eCatalogGridMetrics.maxCrossAxisExtent(
          Md3eWindowSizeClass.extraLarge,
        ),
      ),
    );
  });

  test('crossAxisCount respects max cross axis extent', () {
    expect(
      Md3eCatalogGridMetrics.crossAxisCount(
        1200,
        Md3eWindowSizeClass.expanded,
      ),
      greaterThan(4),
    );
    expect(
      Md3eCatalogGridMetrics.crossAxisCount(
        400,
        Md3eWindowSizeClass.compact,
      ),
      2,
    );
  });

  test('resolve includes main axis extent from cell width', () {
    final M3ESpacing spacing = buildMd3eThemeData().spacing;
    final Md3eCatalogGridLayout layout = Md3eCatalogGridMetrics.resolve(
      viewportWidth: 800,
      spacing: spacing,
    );
    expect(layout.mainAxisExtent, greaterThan(layout.cellWidth));
  });

  test('layout cell width matches inner viewport', () {
    const double width = 360;
    final Md3eCatalogGridLayout layout =
        Md3eCatalogGridMetrics.layoutForViewportWidth(width);
    final double inner = width - layout.horizontalMargin * 2;
    final double reconstructed = layout.cellWidth * layout.crossAxisCount +
        layout.gutter * (layout.crossAxisCount - 1);
    expect(reconstructed, closeTo(inner, 0.01));
  });
}
