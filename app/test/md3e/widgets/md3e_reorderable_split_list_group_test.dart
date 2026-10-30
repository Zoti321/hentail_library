import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/md3e/widgets/lists/md3e_reorder_exclude.dart';
import 'package:hentai_library/md3e/widgets/lists/md3e_reorder_index.dart';
import 'package:hentai_library/md3e/widgets/settings/md3e_reorderable_split_list_group.dart';
import 'package:hentai_library/md3e/widgets/settings/md3e_split_list_group.dart';
import 'package:hentai_library/md3e/widgets/settings/md3e_tonal_surface.dart';

import '../../support/pump_md3e_app.dart';

const List<String> _items = <String>['A', 'B', 'C'];

Future<void> _pumpGroup(
  WidgetTester tester, {
  required void Function(int oldIndex, int newIndex) onReorder,
  List<String> items = _items,
}) {
  return pumpMd3eApp(
    tester,
    home: Scaffold(
      body: SingleChildScrollView(
        child: Md3eReorderableSplitListGroup(
          itemCount: items.length,
          onReorder: onReorder,
          itemBuilder: (BuildContext context, int index) =>
              SizedBox(height: 56, child: Center(child: Text(items[index]))),
        ),
      ),
    ),
  );
}

/// 长按 [start] 超过长按阈值后向下拖动 [dy]，再抬起。
Future<void> _longPressDrag(
  WidgetTester tester,
  Finder start, {
  required double dy,
}) async {
  final TestGesture gesture = await tester.startGesture(
    tester.getCenter(start),
  );
  await tester.pump(const Duration(milliseconds: 600));
  for (int i = 0; i < 10; i++) {
    await gesture.moveBy(Offset(0, dy / 10));
    await tester.pump(const Duration(milliseconds: 16));
  }
  await gesture.up();
  await tester.pumpAndSettle();
}

void main() {
  group('Md3eReorderableSplitListGroup', () {
    testWidgets('每行圆角：首行上圆角与末行下圆角为外圆角，其余为内圆角', (WidgetTester tester) async {
      await _pumpGroup(tester, onReorder: (int _, int _) {});

      final List<Md3eSplitListRow> rows = tester
          .widgetList<Md3eSplitListRow>(find.byType(Md3eSplitListRow))
          .toList();

      expect(rows, hasLength(3));
      expect(rows.first.topRadius, kMd3eTonalSurfaceRadius);
      expect(rows.first.bottomRadius, kMd3eSplitListInnerRadius);
      expect(rows[1].topRadius, kMd3eSplitListInnerRadius);
      expect(rows[1].bottomRadius, kMd3eSplitListInnerRadius);
      expect(rows.last.topRadius, kMd3eSplitListInnerRadius);
      expect(rows.last.bottomRadius, kMd3eTonalSurfaceRadius);
    });

    testWidgets('未拖拽时与 Md3eSplitListGroup 的行位置、尺寸、圆角完全一致', (
      WidgetTester tester,
    ) async {
      Widget child(int index) =>
          SizedBox(height: 56, child: Center(child: Text(_items[index])));

      await pumpMd3eApp(
        tester,
        home: Scaffold(
          body: Md3eSplitListGroup(
            children: <Widget>[for (int i = 0; i < 3; i++) child(i)],
          ),
        ),
      );
      final List<Rect> staticRects = <Rect>[
        for (final String t in _items) tester.getRect(find.text(t)),
      ];
      final List<(double, double, Size)> staticRows = <(double, double, Size)>[
        for (final Md3eSplitListRow r in tester.widgetList<Md3eSplitListRow>(
          find.byType(Md3eSplitListRow),
        ))
          (r.topRadius, r.bottomRadius, tester.getSize(find.byWidget(r))),
      ];

      await pumpMd3eApp(
        tester,
        home: Scaffold(
          body: Md3eReorderableSplitListGroup(
            itemCount: 3,
            onReorder: (int _, int _) {},
            itemBuilder: (BuildContext context, int index) => child(index),
          ),
        ),
      );
      final List<Rect> reorderRects = <Rect>[
        for (final String t in _items) tester.getRect(find.text(t)),
      ];
      final List<(double, double, Size)> reorderRows = <(double, double, Size)>[
        for (final Md3eSplitListRow r in tester.widgetList<Md3eSplitListRow>(
          find.byType(Md3eSplitListRow),
        ))
          (r.topRadius, r.bottomRadius, tester.getSize(find.byWidget(r))),
      ];

      expect(reorderRects, staticRects);
      expect(reorderRows, staticRows);
    });

    testWidgets('长按首行并向下拖动会回调重排（Flutter newIndex 约定）', (
      WidgetTester tester,
    ) async {
      final List<(int, int)> calls = <(int, int)>[];
      await _pumpGroup(
        tester,
        onReorder: (int from, int to) => calls.add((from, to)),
      );

      // 拖过两行的高度，落到末尾。
      await _longPressDrag(tester, find.text('A'), dy: 150);

      expect(calls, hasLength(1));
      final (int from, int to) = calls.single;
      expect(from, 0);
      expect(applyMd3eReorder(_items, from, to), <String>['B', 'C', 'A']);
    });

    testWidgets('行高不同时拖动仍按各行真实位置判定目标（不因高度错位）', (WidgetTester tester) async {
      const List<double> heights = <double>[56, 120, 56];
      final List<(int, int)> calls = <(int, int)>[];
      await pumpMd3eApp(
        tester,
        home: Scaffold(
          body: SingleChildScrollView(
            child: Md3eReorderableSplitListGroup(
              itemCount: heights.length,
              onReorder: (int from, int to) => calls.add((from, to)),
              itemBuilder: (BuildContext context, int index) => SizedBox(
                height: heights[index],
                child: Center(child: Text(_items[index])),
              ),
            ),
          ),
        ),
      );

      // A 下移 150：中心越过 B 的中线（120），但未越过 C 的中线（212）。
      await _longPressDrag(tester, find.text('A'), dy: 150);

      expect(calls, hasLength(1));
      final (int from, int to) = calls.single;
      expect(applyMd3eReorder(_items, from, to), <String>['B', 'A', 'C']);
    });

    testWidgets('拖拽过程中存在浮层（Md3eSplitDragScope），松手后移除', (
      WidgetTester tester,
    ) async {
      await _pumpGroup(tester, onReorder: (int _, int _) {});

      final TestGesture gesture = await tester.startGesture(
        tester.getCenter(find.text('A')),
      );
      await tester.pump(const Duration(milliseconds: 600));
      await gesture.moveBy(const Offset(0, 20));
      await tester.pump(const Duration(milliseconds: 16));

      expect(find.byType(Md3eSplitDragScope), findsOneWidget);

      await gesture.up();
      await tester.pumpAndSettle();
      expect(find.byType(Md3eSplitDragScope), findsNothing);
    });

    testWidgets('点击行时触发 onItemTap，点击 Md3eReorderExclude 区域不触发', (
      WidgetTester tester,
    ) async {
      final List<int> taps = <int>[];
      await pumpMd3eApp(
        tester,
        home: Scaffold(
          body: SingleChildScrollView(
            child: Md3eReorderableSplitListGroup(
              itemCount: 2,
              onReorder: (int _, int _) {},
              onItemTap: taps.add,
              itemBuilder: (BuildContext context, int index) => SizedBox(
                height: 56,
                child: Row(
                  children: <Widget>[
                    Expanded(child: Text('row-$index')),
                    Md3eReorderExclude(
                      child: IconButton(
                        key: ValueKey<String>('control-$index'),
                        icon: const Icon(Icons.tune),
                        onPressed: () {},
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('row-1'));
      await tester.pumpAndSettle();
      expect(taps, <int>[1]);

      await tester.tap(find.byKey(const ValueKey<String>('control-1')));
      await tester.pumpAndSettle();
      expect(taps, <int>[1]);
    });

    testWidgets('长按 Md3eReorderExclude 区域不会开始拖拽', (WidgetTester tester) async {
      final List<(int, int)> calls = <(int, int)>[];
      await pumpMd3eApp(
        tester,
        home: Scaffold(
          body: SingleChildScrollView(
            child: Md3eReorderableSplitListGroup(
              itemCount: 2,
              onReorder: (int from, int to) => calls.add((from, to)),
              itemBuilder: (BuildContext context, int index) => SizedBox(
                height: 56,
                child: Row(
                  children: <Widget>[
                    const Expanded(child: SizedBox()),
                    Md3eReorderExclude(
                      child: IconButton(
                        key: ValueKey<String>('control-$index'),
                        icon: const Icon(Icons.tune),
                        onPressed: () {},
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );

      await _longPressDrag(
        tester,
        find.byKey(const ValueKey<String>('control-0')),
        dy: 150,
      );

      expect(calls, isEmpty);
    });
  });
}
