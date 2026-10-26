import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/md3e/theme/md3e_theme.dart';
import 'package:hentai_library/md3e/widgets/desktop/md3e_desktop_title_bar.dart';
import 'package:hentai_library/md3e/widgets/desktop/md3e_desktop_title_bar_metrics.dart';
import 'package:hentai_library/md3e/widgets/desktop/md3e_navigation_rail.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

import '../../support/pump_md3e_app.dart';

void main() {
  testWidgets('Md3eDesktopTitleBar is 64dp tall with shell chrome color', (
    WidgetTester tester,
  ) async {
    final M3EThemeData m3e = buildMd3eThemeData();
    await tester.binding.setSurfaceSize(const Size(1024, 200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await pumpMd3eApp(
      tester,
      home: Align(
        alignment: Alignment.topCenter,
        child: Md3eDesktopTitleBar(
          railWidth: Md3eNavigationRailMetrics.collapsedWidth,
        ),
      ),
    );

    expect(
      tester.getSize(find.byType(Md3eDesktopTitleBar)).height,
      Md3eDesktopTitleBarMetrics.height,
    );

    final ColoredBox chrome = tester.widget<ColoredBox>(
      find.descendant(
        of: find.byType(Md3eDesktopTitleBar),
        matching: find.byType(ColoredBox),
      ).first,
    );
    expect(chrome.color, m3e.colorScheme.surfaceContainerLow);
  });

  testWidgets('shows search field and window control placeholders', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1024, 200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await pumpMd3eApp(
      tester,
      home: Align(
        alignment: Alignment.topCenter,
        child: Md3eDesktopTitleBar(
          railWidth: Md3eNavigationRailMetrics.collapsedWidth,
        ),
      ),
    );

    expect(find.byType(M3ESearchBar), findsOneWidget);
    expect(find.byType(M3EIconButton), findsNWidgets(3));
  });

  testWidgets('narrow width does not throw when search slot collapses', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await pumpMd3eApp(
      tester,
      home: Md3eDesktopTitleBar(
        railWidth: Md3eNavigationRailMetrics.collapsedWidth,
      ),
    );

    expect(tester.takeException(), isNull);
  });
}
