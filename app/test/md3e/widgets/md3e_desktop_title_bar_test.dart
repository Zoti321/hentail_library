import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../widgetbook/lab/theme/md3e_theme.dart';

import 'package:hentai_library/shared/ui/widgets/desktop/desktop_title_bar.dart';
import 'package:hentai_library/shared/ui/widgets/desktop/desktop_title_bar_metrics.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

import '../../support/pump_md3e_app.dart';

void main() {
  testWidgets('Md3eDesktopTitleBar is compact (36dp) with shell chrome color', (
    WidgetTester tester,
  ) async {
    final M3EThemeData m3e = buildMd3eThemeData();
    await tester.binding.setSurfaceSize(const Size(1024, 200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await pumpMd3eApp(
      tester,
      home: const Align(
        alignment: Alignment.topCenter,
        child: Md3eDesktopTitleBar(),
      ),
    );

    expect(
      tester.getSize(find.byType(Md3eDesktopTitleBar)).height,
      Md3eDesktopTitleBarMetrics.height,
    );
    expect(Md3eDesktopTitleBarMetrics.height, 36);

    final ColoredBox chrome = tester.widget<ColoredBox>(
      find
          .descendant(
            of: find.byType(Md3eDesktopTitleBar),
            matching: find.byType(ColoredBox),
          )
          .first,
    );
    expect(chrome.color, m3e.colorScheme.surfaceContainerLow);
  });

  testWidgets('title bar has no search field and shows window controls', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1024, 200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await pumpMd3eApp(
      tester,
      home: const Align(
        alignment: Alignment.topCenter,
        child: Md3eDesktopTitleBar(),
      ),
    );

    expect(find.byType(M3ESearchBar), findsNothing);
    expect(find.byType(M3EIconButton), findsNWidgets(3));
  });

  testWidgets('narrow width does not throw', (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await pumpMd3eApp(tester, home: const Md3eDesktopTitleBar());

    expect(tester.takeException(), isNull);
  });
}
