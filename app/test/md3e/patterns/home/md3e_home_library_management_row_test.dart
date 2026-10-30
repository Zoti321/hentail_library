import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/md3e/patterns/home/md3e_home_library_dashboard_models.dart';
import 'package:hentai_library/md3e/patterns/home/md3e_home_library_management_section.dart';
import 'package:hentai_library/md3e/widgets/settings/md3e_reorderable_split_list_group.dart';
import 'package:hentai_library/md3e/widgets/settings/md3e_split_list_group.dart';
import 'package:hentai_library/md3e/widgets/settings/md3e_tonal_surface.dart';

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

Future<void> _pumpSection(
  WidgetTester tester, {
  ValueChanged<String>? onLibraryOpen,
  void Function(int oldIndex, int newIndex)? onLibrariesReorder,
}) {
  return pumpMd3eApp(
    tester,
    home: Scaffold(
      body: SingleChildScrollView(
        child: Md3eHomeLibraryManagementSection(
          libraries: _rows,
          onLibraryOpen: onLibraryOpen,
          onLibrariesReorder: onLibrariesReorder,
        ),
      ),
    ),
  );
}

void main() {
  group('首页库列表（设置页同款分段列表）', () {
    testWidgets('列表使用 Md3eSplitListGroup：首行上圆角、末行下圆角为外圆角', (
      WidgetTester tester,
    ) async {
      await _pumpSection(tester);

      expect(find.byType(Md3eSplitListGroup), findsOneWidget);
      final List<Md3eSplitListRow> rows = tester
          .widgetList<Md3eSplitListRow>(find.byType(Md3eSplitListRow))
          .toList();

      expect(rows, hasLength(2));
      expect(rows.first.topRadius, kMd3eTonalSurfaceRadius);
      expect(rows.first.bottomRadius, kMd3eSplitListInnerRadius);
      expect(rows.last.topRadius, kMd3eSplitListInnerRadius);
      expect(rows.last.bottomRadius, kMd3eTonalSurfaceRadius);
    });

    testWidgets('无 onOpen 时行仍挂载可点按表面（保留 state layer），点击无动作', (
      WidgetTester tester,
    ) async {
      await _pumpSection(tester);

      final InkWell ink = tester.widget<InkWell>(find.byType(InkWell).first);
      expect(ink.onTap, isNotNull);

      await tester.tap(find.text('演示库A'));
      await tester.pumpAndSettle();
    });

    testWidgets('点按层铺满整行宽度（含「更多」区域），state layer 不缺角', (
      WidgetTester tester,
    ) async {
      await _pumpSection(tester);

      final Size rowSize = tester.getSize(
        find.byType(Md3eHomeLibraryDashboardTile).first,
      );
      final Size inkSize = tester.getSize(find.byType(InkWell).first);
      expect(inkSize.width, rowSize.width);
    });

    testWidgets('点击行内容触发打开回调', (WidgetTester tester) async {
      String? opened;
      await _pumpSection(tester, onLibraryOpen: (String id) => opened = id);

      await tester.tap(find.text('演示库A'));
      await tester.pumpAndSettle();

      expect(opened, 'lib-a');
    });

    testWidgets('点击「更多」只打开菜单，不触发整行打开', (WidgetTester tester) async {
      String? opened;
      await _pumpSection(tester, onLibraryOpen: (String id) => opened = id);

      await tester.tap(find.byIcon(Icons.more_vert).first);
      await tester.pumpAndSettle();

      expect(opened, isNull);
    });

    testWidgets('传入 onLibrariesReorder 时使用可拖拽分段组，长按行可拖动重排', (
      WidgetTester tester,
    ) async {
      final List<(int, int)> calls = <(int, int)>[];
      await _pumpSection(
        tester,
        onLibrariesReorder: (int from, int to) => calls.add((from, to)),
      );

      expect(find.byType(Md3eReorderableSplitListGroup), findsOneWidget);

      final TestGesture gesture = await tester.startGesture(
        tester.getCenter(find.text('演示库A')),
      );
      await tester.pump(const Duration(milliseconds: 600));
      for (int i = 0; i < 10; i++) {
        await gesture.moveBy(const Offset(0, 40));
        await tester.pump(const Duration(milliseconds: 16));
      }
      await gesture.up();
      await tester.pumpAndSettle();

      expect(calls, <(int, int)>[(0, 2)]);
    });

    testWidgets('长按「更多」不会开始拖拽', (WidgetTester tester) async {
      final List<(int, int)> calls = <(int, int)>[];
      await _pumpSection(
        tester,
        onLibrariesReorder: (int from, int to) => calls.add((from, to)),
      );

      final TestGesture gesture = await tester.startGesture(
        tester.getCenter(find.byIcon(Icons.more_vert).first),
      );
      await tester.pump(const Duration(milliseconds: 600));
      for (int i = 0; i < 10; i++) {
        await gesture.moveBy(const Offset(0, 40));
        await tester.pump(const Duration(milliseconds: 16));
      }
      await gesture.up();
      await tester.pumpAndSettle();

      expect(calls, isEmpty);
    });
  });
}
