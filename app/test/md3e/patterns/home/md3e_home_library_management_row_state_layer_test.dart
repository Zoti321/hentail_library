import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/md3e/patterns/home/md3e_home_library_dashboard_models.dart';
import 'package:hentai_library/md3e/patterns/home/md3e_home_library_management_section.dart';
import 'package:hentai_library/md3e/widgets/settings/md3e_split_list_group.dart';
import 'package:hentai_library/md3e/widgets/settings/md3e_tonal_surface.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

import '../../../support/pump_md3e_app.dart';

const Md3eHomeLibraryDashboardRow _row = Md3eHomeLibraryDashboardRow(
  libraryId: 'lib-1',
  displayName: '演示库',
  kind: Md3eHomeLibraryKind.local,
  comicCount: 3,
  seriesCount: 1,
);

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
          libraries: const <Md3eHomeLibraryDashboardRow>[_row],
          onLibraryOpen: onLibraryOpen,
          onLibrariesReorder: onLibrariesReorder,
        ),
      ),
    ),
  );
}

/// 列表行上的 M3E state layer（即 [M3ECard] 的交互表面）。
M3EStateLayerOverlay _rowStateLayer(WidgetTester tester) {
  return tester.widget<M3EStateLayerOverlay>(
    find.byType(M3EStateLayerOverlay).first,
  );
}

Future<void> _hoverRow(WidgetTester tester) async {
  final TestGesture mouse = await tester.createGesture(
    kind: PointerDeviceKind.mouse,
  );
  addTearDown(mouse.removePointer);
  await mouse.addPointer(location: Offset.zero);
  await mouse.moveTo(tester.getCenter(find.text('演示库')));
  await tester.pump();
}

void main() {
  group('非拖拽列表（无 onLibrariesReorder）', () {
    testWidgets('无 onOpen 时 hover 仍显示 state layer', (
      WidgetTester tester,
    ) async {
      await _pumpSection(tester);

      await _hoverRow(tester);

      expect(_rowStateLayer(tester).state.hovered, isTrue);
    });

    testWidgets('无 onOpen 时按压仍显示 state layer 的按压态', (
      WidgetTester tester,
    ) async {
      await _pumpSection(tester);

      final TestGesture press = await tester.startGesture(
        tester.getCenter(find.text('演示库')),
      );
      await tester.pump();

      expect(_rowStateLayer(tester).state.pressed, isTrue);
      await press.up();
      await tester.pumpAndSettle();
    });

    testWidgets('hover 不改变圆角，按压后圆角变为统计卡片同款的 24dp', (WidgetTester tester) async {
      await _pumpSection(tester);
      final Finder card = find.byType(M3ECard).first;
      final BorderRadius resting = tester.widget<M3ECard>(card).borderRadius!;

      await _hoverRow(tester);
      await tester.pumpAndSettle();
      expect(tester.widget<M3ECard>(card).borderRadius, resting);

      final TestGesture press = await tester.startGesture(
        tester.getCenter(find.text('演示库')),
      );
      await tester.pumpAndSettle();
      expect(
        tester.widget<M3ECard>(card).borderRadius,
        BorderRadius.circular(kMd3eTonalSurfaceRadius),
      );
      await press.up();
      await tester.pumpAndSettle();
    });

    testWidgets('无 onOpen 时行不呈现可点击光标', (WidgetTester tester) async {
      await _pumpSection(tester);

      final M3ECard card = tester.widget<M3ECard>(find.byType(M3ECard).first);
      expect(card.mouseCursor, SystemMouseCursors.basic);
      expect(card.focusable, isFalse);
      expect(card.haptic, M3EHapticFeedback.none);
    });

    testWidgets('有 onOpen 时点击行仍触发打开回调', (WidgetTester tester) async {
      String? opened;
      await _pumpSection(tester, onLibraryOpen: (String id) => opened = id);

      await tester.tap(find.text('演示库'));
      await tester.pumpAndSettle();

      expect(opened, 'lib-1');
    });

    testWidgets('有 onOpen 时光标为可点击', (WidgetTester tester) async {
      await _pumpSection(tester, onLibraryOpen: (_) {});

      final M3ECard card = tester.widget<M3ECard>(find.byType(M3ECard).first);
      expect(card.mouseCursor, SystemMouseCursors.click);
      expect(card.focusable, isTrue);
    });

    testWidgets('点击「更多」只打开菜单，不让整行进入按压态', (WidgetTester tester) async {
      String? opened;
      await _pumpSection(tester, onLibraryOpen: (String id) => opened = id);

      final TestGesture press = await tester.startGesture(
        tester.getCenter(find.byIcon(Icons.more_vert)),
      );
      await tester.pump();

      expect(_rowStateLayer(tester).state.pressed, isFalse);
      await press.up();
      await tester.pumpAndSettle();
      expect(opened, isNull);
    });
  });

  group('可拖拽列表（提供 onLibrariesReorder）', () {
    testWidgets('无 onOpen 时行不可点击（不挂载行级 InkWell，光标保持普通箭头）', (
      WidgetTester tester,
    ) async {
      await _pumpSection(tester, onLibrariesReorder: (int _, int _) {});

      final Md3eSplitListRow row = tester.widget<Md3eSplitListRow>(
        find.byType(Md3eSplitListRow).first,
      );
      expect(row.onTap, isNull);
      expect(find.byType(InkWell), findsNothing);
    });

    testWidgets('有 onOpen 时行挂载 InkWell 并带点击光标', (WidgetTester tester) async {
      await _pumpSection(
        tester,
        onLibraryOpen: (_) {},
        onLibrariesReorder: (int _, int _) {},
      );

      final InkWell ink = tester.widget<InkWell>(find.byType(InkWell).first);
      expect(ink.mouseCursor, SystemMouseCursors.click);
    });

    testWidgets('有 onOpen 时点击行仍触发打开回调', (WidgetTester tester) async {
      String? opened;
      await _pumpSection(
        tester,
        onLibraryOpen: (String id) => opened = id,
        onLibrariesReorder: (int _, int _) {},
      );

      await tester.tap(find.text('演示库'));
      await tester.pumpAndSettle();

      expect(opened, 'lib-1');
    });
  });
}
