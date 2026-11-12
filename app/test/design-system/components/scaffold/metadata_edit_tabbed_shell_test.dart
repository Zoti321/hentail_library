import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/design-system/design_system.dart';

import '../../../support/pump_app.dart';

List<MetadataEditTab> _tabs() {
  return <MetadataEditTab>[
    (label: '常规', body: const Text('body-general')),
    (label: '作者与标签', body: const Text('body-facets')),
    (label: '字段锁', body: const Text('body-locks')),
  ];
}

Future<void> _pumpShell(
  WidgetTester tester, {
  required Size size,
  int initialIndex = 0,
  ValueChanged<int>? onSelected,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  int index = initialIndex;
  await pumpApp(
    tester,
    home: Scaffold(
      body: StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {
          return MetadataEditTabbedShell(
            tabs: _tabs(),
            selectedIndex: index,
            onSelected: (int next) {
              setState(() => index = next);
              onSelected?.call(next);
            },
          );
        },
      ),
    ),
  );
}

void main() {
  testWidgets('宽屏渲染侧栏列表并回调索引', (WidgetTester tester) async {
    int selected = -1;
    await _pumpShell(
      tester,
      size: const Size(1200, 900),
      onSelected: (int index) => selected = index,
    );

    expect(find.byType(ListDetailNavItem), findsNWidgets(3));
    expect(find.byType(SegmentedCapsuleBar), findsNothing);
    expect(find.text('body-general'), findsOneWidget);

    await tester.tap(find.text('作者与标签'));
    await tester.pumpAndSettle();

    expect(selected, 1);
    expect(find.text('body-facets'), findsOneWidget);
  });

  testWidgets('窄屏渲染顶部分段条并回调索引', (WidgetTester tester) async {
    int selected = -1;
    await _pumpShell(
      tester,
      size: const Size(400, 800),
      onSelected: (int index) => selected = index,
    );

    expect(find.byType(SegmentedCapsuleBar), findsOneWidget);
    expect(find.byType(ListDetailNavItem), findsNothing);

    await tester.tap(find.text('字段锁'));
    await tester.pumpAndSettle();

    expect(selected, 2);
    expect(find.text('body-locks'), findsOneWidget);
  });

  testWidgets('向前切换时详情过渡标记为反向', (WidgetTester tester) async {
    await _pumpShell(tester, size: const Size(1200, 900), initialIndex: 2);

    expect(
      tester
          .widget<ListDetailDetailTransition>(
            find.byType(ListDetailDetailTransition),
          )
          .reverse,
      isFalse,
    );

    await tester.tap(find.text('常规'));
    await tester.pumpAndSettle();

    expect(
      tester
          .widget<ListDetailDetailTransition>(
            find.byType(ListDetailDetailTransition),
          )
          .reverse,
      isTrue,
    );
  });
}
