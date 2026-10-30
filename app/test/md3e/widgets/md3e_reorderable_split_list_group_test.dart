import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/md3e/widgets/lists/md3e_reorder_index.dart';
import 'package:hentai_library/md3e/widgets/settings/md3e_split_list_group.dart';
import 'package:hentai_library/md3e/widgets/settings/md3e_tonal_surface.dart';
import 'package:material_3_expressive/components/lists/components/m3e_list_drag_proxy_scope.dart';
import 'package:material_3_expressive/components/lists/components/m3e_list_reorder_exclude.dart';

import '../../support/pump_md3e_app.dart';

const List<String> _items = <String>['A', 'B', 'C'];

Future<void> _pumpGroup(
  WidgetTester tester, {
  required ReorderCallback onReorder,
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
  bool settle = true,
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
  if (settle) {
    await tester.pumpAndSettle();
  }
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

    testWidgets('拖拽过程中存在浮层 proxy（M3EListDragProxyScope）', (
      WidgetTester tester,
    ) async {
      await _pumpGroup(tester, onReorder: (int _, int _) {});

      final TestGesture gesture = await tester.startGesture(
        tester.getCenter(find.text('A')),
      );
      await tester.pump(const Duration(milliseconds: 600));
      await gesture.moveBy(const Offset(0, 20));
      await tester.pump(const Duration(milliseconds: 16));

      expect(find.byType(M3EListDragProxyScope), findsOneWidget);

      await gesture.up();
      await tester.pumpAndSettle();
      expect(find.byType(M3EListDragProxyScope), findsNothing);
    });

    testWidgets('长按 M3EListReorderExclude 区域不会开始拖拽', (
      WidgetTester tester,
    ) async {
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
                    M3EListReorderExclude(
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
