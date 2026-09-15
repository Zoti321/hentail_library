import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/ui/core/layout/detail_meta_chip_band_layout.dart';
import 'package:hentai_library/ui/core/layout/detail_meta_chip_row_layout.dart';
import 'package:hentai_library/ui/core/widgets/element/chip/detail_meta_chip_band.dart';
import 'package:hentai_library/ui/core/widgets/foundation/horizontal_wheel_scroll_listener.dart';

import '../../../../../support/pump_localized_app.dart';

const double _kChipW = 40;
const double _kChipH = kDetailMetaChipRowHeight;
const double _kSpacing = 8;
const double _kAvailable = 100;

List<Widget> _fixedChips(int count) {
  return List<Widget>.generate(
    count,
    (int i) => SizedBox(width: _kChipW, height: _kChipH, child: Text('c$i')),
  );
}

double _bandHeight(int usedRows) =>
    usedRows * _kChipH + (usedRows - 1) * _kSpacing;

Future<void> _pumpBand(
  WidgetTester tester, {
  required int maxRows,
  required List<Widget> children,
  double width = _kAvailable,
}) async {
  await pumpLocalizedApp(
    tester,
    home: Scaffold(
      body: SizedBox(
        width: width,
        child: DetailMetaChipBand(maxRows: maxRows, children: children),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

ScrollPosition _scrollPosition(WidgetTester tester) {
  final ScrollableState state = tester.state(find.byType(Scrollable));
  return state.position;
}

void main() {
  group('layoutDetailMetaChipBand', () {
    test('maxRows 1: single-row height; wider content when overflow', () {
      final DetailMetaChipBandLayout fit = layoutDetailMetaChipBand(
        chipWidths: const <double>[_kChipW, _kChipW],
        availableWidth: _kAvailable,
        maxRows: 1,
        spacing: _kSpacing,
        runSpacing: _kSpacing,
        rowHeight: _kChipH,
      );
      // 40+8+40 = 88 <= 100
      expect(fit.usedRows, 1);
      expect(fit.bandHeight, _bandHeight(1));
      expect(fit.contentWidth, _kAvailable);

      final DetailMetaChipBandLayout overflow = layoutDetailMetaChipBand(
        chipWidths: const <double>[_kChipW, _kChipW, _kChipW],
        availableWidth: _kAvailable,
        maxRows: 1,
        spacing: _kSpacing,
        runSpacing: _kSpacing,
        rowHeight: _kChipH,
      );
      // three chips need 40*3+8*2 = 136
      expect(overflow.usedRows, 1);
      expect(overflow.bandHeight, _bandHeight(1));
      expect(overflow.contentWidth, greaterThan(_kAvailable));
    });

    test('maxRows 2: underfull shorter; overfull locks two-row height', () {
      final DetailMetaChipBandLayout underfull = layoutDetailMetaChipBand(
        chipWidths: const <double>[_kChipW, _kChipW],
        availableWidth: _kAvailable,
        maxRows: 2,
        spacing: _kSpacing,
        runSpacing: _kSpacing,
        rowHeight: _kChipH,
      );
      expect(underfull.usedRows, 1);
      expect(underfull.bandHeight, lessThan(_bandHeight(2)));

      final DetailMetaChipBandLayout twoRows = layoutDetailMetaChipBand(
        chipWidths: const <double>[_kChipW, _kChipW, _kChipW],
        availableWidth: _kAvailable,
        maxRows: 2,
        spacing: _kSpacing,
        runSpacing: _kSpacing,
        rowHeight: _kChipH,
      );
      // at 100: row1 two chips, row2 one → fits in 2 rows
      expect(twoRows.usedRows, 2);
      expect(twoRows.bandHeight, _bandHeight(2));
      expect(twoRows.contentWidth, _kAvailable);

      final DetailMetaChipBandLayout overfull = layoutDetailMetaChipBand(
        chipWidths: List<double>.filled(8, _kChipW),
        availableWidth: _kAvailable,
        maxRows: 2,
        spacing: _kSpacing,
        runSpacing: _kSpacing,
        rowHeight: _kChipH,
      );
      expect(overfull.usedRows, lessThanOrEqualTo(2));
      expect(overfull.bandHeight, lessThanOrEqualTo(_bandHeight(2)));
      expect(overfull.contentWidth, greaterThan(_kAvailable));
    });

    test('maxRows 3: same underfull / overfull pattern', () {
      final DetailMetaChipBandLayout underfull = layoutDetailMetaChipBand(
        chipWidths: const <double>[_kChipW],
        availableWidth: _kAvailable,
        maxRows: 3,
        spacing: _kSpacing,
        runSpacing: _kSpacing,
        rowHeight: _kChipH,
      );
      expect(underfull.usedRows, 1);
      expect(underfull.bandHeight, _bandHeight(1));

      final DetailMetaChipBandLayout overfull = layoutDetailMetaChipBand(
        chipWidths: List<double>.filled(12, _kChipW),
        availableWidth: _kAvailable,
        maxRows: 3,
        spacing: _kSpacing,
        runSpacing: _kSpacing,
        rowHeight: _kChipH,
      );
      expect(overfull.usedRows, lessThanOrEqualTo(3));
      expect(overfull.bandHeight, lessThanOrEqualTo(_bandHeight(3)));
      expect(overfull.contentWidth, greaterThan(_kAvailable));
    });

    test('empty chip list: zero height band', () {
      final DetailMetaChipBandLayout empty = layoutDetailMetaChipBand(
        chipWidths: const <double>[],
        availableWidth: _kAvailable,
        maxRows: 3,
        spacing: _kSpacing,
        runSpacing: _kSpacing,
        rowHeight: _kChipH,
      );
      expect(empty.usedRows, 0);
      expect(empty.bandHeight, 0);
      expect(empty.contentWidth, 0);
    });
  });

  group('DetailMetaChipBand widget', () {
    testWidgets('maxRows 1: single-row height; scrolls when overflow', (
      WidgetTester tester,
    ) async {
      await _pumpBand(tester, maxRows: 1, children: _fixedChips(2));
      expect(tester.getSize(find.byType(DetailMetaChipBand)).height, _kChipH);
      expect(_scrollPosition(tester).maxScrollExtent, 0);

      await _pumpBand(tester, maxRows: 1, children: _fixedChips(3));
      expect(tester.getSize(find.byType(DetailMetaChipBand)).height, _kChipH);
      expect(_scrollPosition(tester).maxScrollExtent, greaterThan(0));
      expect(find.byType(HorizontalWheelScrollListener), findsOneWidget);
    });

    testWidgets(
      'maxRows 2: underfull shorter; overfull scrolls at 2-row height',
      (WidgetTester tester) async {
        await _pumpBand(tester, maxRows: 2, children: _fixedChips(2));
        expect(
          tester.getSize(find.byType(DetailMetaChipBand)).height,
          _bandHeight(1),
        );
        expect(_scrollPosition(tester).maxScrollExtent, 0);

        await _pumpBand(tester, maxRows: 2, children: _fixedChips(8));
        expect(
          tester.getSize(find.byType(DetailMetaChipBand)).height,
          lessThanOrEqualTo(_bandHeight(2)),
        );
        expect(
          tester.getSize(find.byType(DetailMetaChipBand)).height,
          greaterThan(_bandHeight(1)),
        );
        expect(_scrollPosition(tester).maxScrollExtent, greaterThan(0));
      },
    );

    testWidgets('maxRows 3: underfull shorter; overfull scrolls at 3-row cap', (
      WidgetTester tester,
    ) async {
      await _pumpBand(tester, maxRows: 3, children: _fixedChips(1));
      expect(
        tester.getSize(find.byType(DetailMetaChipBand)).height,
        _bandHeight(1),
      );

      await _pumpBand(tester, maxRows: 3, children: _fixedChips(12));
      expect(
        tester.getSize(find.byType(DetailMetaChipBand)).height,
        lessThanOrEqualTo(_bandHeight(3)),
      );
      expect(
        tester.getSize(find.byType(DetailMetaChipBand)).height,
        greaterThan(_bandHeight(2)),
      );
      expect(_scrollPosition(tester).maxScrollExtent, greaterThan(0));
    });

    testWidgets('empty children: no reserved band height', (
      WidgetTester tester,
    ) async {
      await _pumpBand(tester, maxRows: 3, children: const <Widget>[]);
      expect(find.byType(DetailMetaChipBand), findsOneWidget);
      expect(tester.getSize(find.byType(DetailMetaChipBand)).height, 0);
      expect(find.byType(Scrollable), findsNothing);
    });
  });
}
