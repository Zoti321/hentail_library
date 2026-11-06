import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/shared/ui/layout/breakpoints.dart';
import 'package:hentai_library/shared/ui/widgets/history/reading_history_list_item_metrics.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

void main() {
  group('ReadingHistoryListItemMetrics.specFor', () {
    test('mobile keeps md action buttons for touch targets', () {
      for (final window in WindowSizeClass.values) {
        final spec = ReadingHistoryListItemMetrics.specFor(
          window,
          desktop: false,
        );
        expect(spec.actionButtonSize, M3EIconButtonSize.md);
        expect(spec.actionGap, 8);
      }
    });

    test('desktop shrinks action buttons on narrow windows', () {
      final compact = ReadingHistoryListItemMetrics.specFor(
        WindowSizeClass.compact,
        desktop: true,
      );
      expect(compact.actionButtonSize, M3EIconButtonSize.sm);
      expect(compact.actionGap, 4);
      expect(compact.containerRadius, greaterThanOrEqualTo(16));

      final wide = ReadingHistoryListItemMetrics.specFor(
        WindowSizeClass.extraLarge,
        desktop: true,
      );
      expect(wide.actionButtonSize, M3EIconButtonSize.md);
      expect(wide.actionGap, 8);
    });
  });

  group('ReadingHistoryListItemMetrics.layoutForViewportWidth', () {
    test('single column on phone widths', () {
      final layout = ReadingHistoryListItemMetrics.layoutForViewportWidth(
        390,
      );
      expect(layout.columnCount, 1);
    });

    test('two columns on expanded desktop widths', () {
      final layout = ReadingHistoryListItemMetrics.layoutForViewportWidth(
        1024,
      );
      expect(layout.columnCount, 2);
    });

    test('up to three columns on large widths', () {
      final layout = ReadingHistoryListItemMetrics.layoutForViewportWidth(
        1600,
      );
      expect(layout.columnCount, 3);
    });
  });
}
