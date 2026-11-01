import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/shared/ui/layout/breakpoints.dart';
import 'package:hentai_library/shared/ui/widgets/history/reading_history_list_item_metrics.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

void main() {
  group('Md3eReadingHistoryListItemMetrics.specFor', () {
    test('mobile keeps md action buttons for touch targets', () {
      for (final window in Md3eWindowSizeClass.values) {
        final spec = Md3eReadingHistoryListItemMetrics.specFor(
          window,
          desktop: false,
        );
        expect(spec.actionButtonSize, M3EIconButtonSize.md);
        expect(spec.actionGap, 8);
      }
    });

    test('desktop shrinks action buttons on narrow windows', () {
      final compact = Md3eReadingHistoryListItemMetrics.specFor(
        Md3eWindowSizeClass.compact,
        desktop: true,
      );
      expect(compact.actionButtonSize, M3EIconButtonSize.sm);
      expect(compact.actionGap, 4);
      expect(compact.containerRadius, greaterThanOrEqualTo(16));

      final wide = Md3eReadingHistoryListItemMetrics.specFor(
        Md3eWindowSizeClass.extraLarge,
        desktop: true,
      );
      expect(wide.actionButtonSize, M3EIconButtonSize.md);
      expect(wide.actionGap, 8);
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
