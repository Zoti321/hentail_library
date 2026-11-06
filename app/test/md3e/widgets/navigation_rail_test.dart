import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/core/l10n/app_localizations_x.dart';

import '../../../widgetbook/lab/theme/md3e_theme.dart';

import 'package:hentai_library/shared/ui/widgets/desktop/navigation_rail.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

import '../../support/pump_app.dart';

void main() {
  testWidgets('ExpressiveNavigationRail selects destination and toggles menu', (
    WidgetTester tester,
  ) async {
    var selected = 0;
    var extended = false;

    await pumpApp(
      tester,
      home: StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {
          return ExpressiveNavigationRail(
            destinations: defaultNavigationRailDestinations(context.l10n),
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
    await pumpApp(
      tester,
      home: Builder(
        builder: (BuildContext context) {
          return ExpressiveNavigationRail(
            destinations: defaultNavigationRailDestinations(context.l10n),
            selectedIndex: 0,
            extended: false,
            onDestinationSelected: (_) {},
          );
        },
      ),
    );

    final M3ENavigationRailTheme theme = M3ETheme.of(
      tester.element(find.byType(M3ENavigationRail)),
    ).navigationRailTheme;
    expect(
      theme.collapsedWidth,
      ExpressiveNavigationRailMetrics.collapsedWidth,
    );
    expect(
      theme.expandedMinWidth,
      ExpressiveNavigationRailMetrics.expandedWidth,
    );
    expect(theme.itemVerticalGap, 8);
  });

  testWidgets('rail chrome uses surfaceContainerLow from lab theme', (
    WidgetTester tester,
  ) async {
    final M3EThemeData m3e = buildThemeData();

    await pumpApp(
      tester,
      home: Builder(
        builder: (BuildContext context) {
          return ExpressiveNavigationRail(
            destinations: defaultNavigationRailDestinations(context.l10n),
            selectedIndex: 0,
            extended: false,
            onDestinationSelected: (_) {},
          );
        },
      ),
    );

    final M3ENavigationRailTheme theme = M3ETheme.of(
      tester.element(find.byType(M3ENavigationRail)),
    ).navigationRailTheme;
    expect(theme.containerColor, m3e.colorScheme.surfaceContainerLow);
  });
}
