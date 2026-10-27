import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/md3e/layout/md3e_breakpoints.dart';
import 'package:hentai_library/md3e/widgets/history/md3e_reading_history_list_item_metrics.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

void main() {
  group('Md3eReadingHistoryListItemMetrics.specFor', () {
    test('uses matching action button sizes', () {
      final spec = Md3eReadingHistoryListItemMetrics.specFor(
        Md3eWindowSizeClass.compact,
      );
      expect(spec.actionButtonSize, M3EIconButtonSize.md);
      expect(spec.containerRadius, greaterThanOrEqualTo(16));
    });
  });

  group('Md3eReadingHistoryListItemMetrics.layoutForViewportWidth', () {
    test('single column on phone widths', () {
      final layout = Md3eReadingHistoryListItemMetrics.layoutForViewportWidth(
        390,
      );
      expect(layout.columnCount, 1);
    });

    test('two columns on expanded desktop widths', () {
      final layout = Md3eReadingHistoryListItemMetrics.layoutForViewportWidth(
        1024,
      );
      expect(layout.columnCount, 2);
    });

    test('up to three columns on large widths', () {
      final layout = Md3eReadingHistoryListItemMetrics.layoutForViewportWidth(
        1600,
      );
      expect(layout.columnCount, 3);
    });
  });
}
