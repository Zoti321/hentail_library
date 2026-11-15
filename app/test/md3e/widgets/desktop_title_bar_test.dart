import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:hentai_library/design-system/design_system.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

import '../../support/pump_design_system_app.dart';

void main() {
  testWidgets('DesktopTitleBar is compact (36dp) with browse canvas color', (
    WidgetTester tester,
  ) async {
    final M3EThemeData m3e = assembleAppTheme(Brightness.light).m3e;
    await tester.binding.setSurfaceSize(const Size(1024, 200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await pumpDesignSystemApp(
      tester,
      home: const Align(
        alignment: Alignment.topCenter,
        child: DesktopTitleBar(),
      ),
    );

    expect(
      tester.getSize(find.byType(DesktopTitleBar)).height,
      DesktopTitleBarMetrics.height,
    );
    expect(DesktopTitleBarMetrics.height, 36);

    final ColoredBox chrome = tester.widget<ColoredBox>(
      find
          .descendant(
            of: find.byType(DesktopTitleBar),
            matching: find.byType(ColoredBox),
          )
          .first,
    );
    expect(chrome.color, labBrowseCanvasColor(m3e.colorScheme));
  });

  testWidgets('title bar has no search field and shows window controls', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1024, 200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await pumpDesignSystemApp(
      tester,
      home: const Align(
        alignment: Alignment.topCenter,
        child: DesktopTitleBar(),
      ),
    );

    expect(find.byType(M3ESearchBar), findsNothing);
    expect(find.byType(M3EIconButton), findsNWidgets(3));
  });

  testWidgets('narrow width does not throw', (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await pumpDesignSystemApp(tester, home: const DesktopTitleBar());

    expect(tester.takeException(), isNull);
  });
}
