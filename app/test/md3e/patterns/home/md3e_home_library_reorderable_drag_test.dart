import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/md3e/patterns/home/md3e_home_library_dashboard_models.dart';
import 'package:hentai_library/md3e/patterns/home/md3e_home_library_management_section.dart';

import '../../../support/pump_md3e_app.dart';

const List<Md3eHomeLibraryDashboardRow> _rows = <Md3eHomeLibraryDashboardRow>[
  Md3eHomeLibraryDashboardRow(
    libraryId: 'lib-a',
    displayName: '演示库A',
    kind: Md3eHomeLibraryKind.local,
    comicCount: 3,
    seriesCount: 1,
  ),
  Md3eHomeLibraryDashboardRow(
    libraryId: 'lib-b',
    displayName: '演示库B',
    kind: Md3eHomeLibraryKind.remote,
    comicCount: 5,
    seriesCount: 2,
  ),
];

Future<void> _pumpReorderable(
  WidgetTester tester, {
  required void Function(int oldIndex, int newIndex) onReorder,
}) {
  return pumpMd3eApp(
    tester,
    home: Scaffold(
      body: SingleChildScrollView(
        child: Md3eHomeLibraryManagementSection(
          libraries: _rows,
          onLibrariesReorder: onReorder,
        ),
      ),
    ),
  );
}

/// 长按 [start] 超过长按阈值后向下拖动，再抬起。
Future<void> _longPressDrag(
  WidgetTester tester,
  Finder start, {
  double dy = 200,
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
  group(
    '可拖拽首页库列表（Md3eReorderableSplitListGroup + Md3eHomeLibraryDashboardTile）',
    () {
      testWidgets('长按行并拖动会触发 onLibrariesReorder', (WidgetTester tester) async {
        final List<(int, int)> calls = <(int, int)>[];
        await _pumpReorderable(
          tester,
          onReorder: (int from, int to) => calls.add((from, to)),
        );

        await _longPressDrag(tester, find.text('演示库A'));

        expect(calls, isNotEmpty);
        expect(calls.first.$1, 0);
      });

      testWidgets('长按「更多」不会开始拖拽', (WidgetTester tester) async {
        final List<(int, int)> calls = <(int, int)>[];
        await _pumpReorderable(
          tester,
          onReorder: (int from, int to) => calls.add((from, to)),
        );

        await _longPressDrag(tester, find.byIcon(Icons.more_vert).first);

        expect(calls, isEmpty);
      });

      // 「更多」位于行内，点击它不得触发整行打开（由 Md3eSplitListRow 按 M3EListReorderExclude 区域过滤）。
      testWidgets('点击「更多」不会触发整行打开', (WidgetTester tester) async {
        String? opened;
        await pumpMd3eApp(
          tester,
          home: Scaffold(
            body: SingleChildScrollView(
              child: Md3eHomeLibraryManagementSection(
                libraries: _rows,
                onLibraryOpen: (String id) => opened = id,
                onLibrariesReorder: (int _, int _) {},
              ),
            ),
          ),
        );

        await tester.tap(find.byIcon(Icons.more_vert).first);
        await tester.pumpAndSettle();

        expect(opened, isNull);
      });
    },
  );
}
