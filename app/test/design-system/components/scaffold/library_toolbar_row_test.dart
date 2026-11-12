import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/design-system/design_system.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../support/pump_app.dart';

Future<void> _pumpRow(
  WidgetTester tester, {
  Size size = const Size(400, 800),
  VoidCallback? onBack,
  VoidCallback? onOpenNavigation,
  List<Widget> trailing = const <Widget>[],
  bool? showMenu,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await pumpApp(
    tester,
    home: Scaffold(
      body: LibraryToolbarRow(
        title: const Text('标题'),
        onBack: onBack,
        onOpenNavigation: onOpenNavigation,
        trailing: trailing,
        showMenu: showMenu,
        menuTooltip: '打开导航',
        menuSemanticLabel: '打开导航',
      ),
    ),
  );
}

void main() {
  testWidgets('无返回回调时不渲染返回按钮', (WidgetTester tester) async {
    await _pumpRow(tester);

    expect(find.text('标题'), findsOneWidget);
    expect(find.byType(PageHeaderBackButton), findsNothing);
  });

  testWidgets('有返回回调时渲染返回按钮并触发回调', (WidgetTester tester) async {
    int backs = 0;
    await _pumpRow(tester, onBack: () => backs++);

    expect(find.byType(PageHeaderBackButton), findsOneWidget);
    await tester.tap(find.byType(PageHeaderBackButton));
    expect(backs, 1);
  });

  testWidgets('紧凑屏宽且存在导航回调时显示汉堡并触发回调', (WidgetTester tester) async {
    int opens = 0;
    await _pumpRow(tester, onOpenNavigation: () => opens++);

    final Finder menu = find.byIcon(Symbols.menu);
    expect(menu, findsOneWidget);
    await tester.tap(menu);
    expect(opens, 1);
  });

  testWidgets('展开屏宽隐藏汉堡', (WidgetTester tester) async {
    await _pumpRow(
      tester,
      size: const Size(1200, 800),
      onOpenNavigation: () {},
    );

    expect(find.byIcon(Symbols.menu), findsNothing);
  });

  testWidgets('showMenu 显式开关覆盖屏宽推导', (WidgetTester tester) async {
    await _pumpRow(
      tester,
      size: const Size(1200, 800),
      onOpenNavigation: () {},
      showMenu: true,
    );

    expect(find.byIcon(Symbols.menu), findsOneWidget);
  });

  testWidgets('尾部插槽渲染在标题右侧', (WidgetTester tester) async {
    await _pumpRow(tester, trailing: const <Widget>[Icon(Icons.delete)]);

    expect(find.byIcon(Icons.delete), findsOneWidget);
  });
}
