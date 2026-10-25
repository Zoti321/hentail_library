import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/md3e/layout/md3e_breakpoints.dart';
import 'package:hentai_library/md3e/layout/md3e_catalog_grid_metrics.dart';

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
}
