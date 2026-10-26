import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/md3e/theme/md3e_theme.dart';
import 'package:hentai_library/md3e/widgets/desktop/md3e_navigation_rail.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

import '../../support/pump_md3e_app.dart';

void main() {
  testWidgets('Md3eNavigationRail selects destination and toggles menu', (
    WidgetTester tester,
  ) async {
    var selected = 0;
    var extended = false;

    await pumpMd3eApp(
      tester,
      home: StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {
          return Md3eNavigationRail(
            destinations: md3eDefaultNavigationRailDestinations(),
            selectedIndex: selected,
            extended: extended,
            onDestinationSelected: (int index) =>
                setState(() => selected = index),
            onMenuPressed: () => setState(() => extended = !extended),
          );
        },
      ),
    );

    expect(find.text('漫画库'), findsOneWidget);
    await tester.tap(find.text('漫画库'));
    await tester.pump();
    expect(selected, 1);

    await tester.tap(find.byIcon(Icons.menu));
    await tester.pumpAndSettle();
    expect(extended, isTrue);
    expect(find.byIcon(Icons.menu_open), findsOneWidget);
  });

  testWidgets('collapsed rail uses MASTER shell widths in M3E theme', (
    WidgetTester tester,
  ) async {
    await pumpMd3eApp(
      tester,
      home: Md3eNavigationRail(
        destinations: md3eDefaultNavigationRailDestinations(),
        selectedIndex: 0,
        extended: false,
        onDestinationSelected: (_) {},
      ),
    );

    final M3ENavigationRailTheme theme = M3ETheme.of(
      tester.element(find.byType(M3ENavigationRail)),
    ).navigationRailTheme;
    expect(theme.collapsedWidth, Md3eNavigationRailMetrics.collapsedWidth);
    expect(theme.expandedMinWidth, Md3eNavigationRailMetrics.expandedWidth);
    expect(theme.itemVerticalGap, 8);
  });

  testWidgets('rail chrome uses surfaceContainerLow from lab theme', (
    WidgetTester tester,
  ) async {
    final M3EThemeData m3e = buildMd3eThemeData();

    await pumpMd3eApp(
      tester,
      home: Md3eNavigationRail(
        destinations: md3eDefaultNavigationRailDestinations(),
        selectedIndex: 0,
        extended: false,
        onDestinationSelected: (_) {},
      ),
    );

    final M3ENavigationRailTheme theme = M3ETheme.of(
      tester.element(find.byType(M3ENavigationRail)),
    ).navigationRailTheme;
    expect(theme.containerColor, m3e.colorScheme.surfaceContainerLow);
  });
}
