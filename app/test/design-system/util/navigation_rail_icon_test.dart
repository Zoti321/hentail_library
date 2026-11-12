import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/design-system/util/navigation_rail_icon.dart';
import 'package:material_symbols_icons/symbols.dart';

Widget _wrap(Widget child) =>
    Directionality(textDirection: TextDirection.ltr, child: child);

void main() {
  testWidgets(
    'Material Symbols use fill when selected and icon matches selectedIcon',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        _wrap(
          const NavigationRailIcon(
            icon: Symbols.home,
            selectedIcon: Symbols.home,
            selected: true,
          ),
        ),
      );
      expect(tester.widget<Icon>(find.byType(Icon)).fill, 1);

      await tester.pumpWidget(
        _wrap(
          const NavigationRailIcon(
            icon: Symbols.home,
            selectedIcon: Symbols.home,
            selected: false,
          ),
        ),
      );
      expect(tester.widget<Icon>(find.byType(Icon)).fill, 0);
    },
  );

  testWidgets('explicit outlined/filled pair ignores fill axis', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        const NavigationRailIcon(
          icon: Icons.home_outlined,
          selectedIcon: Icons.home,
          selected: true,
        ),
      ),
    );
    final Icon selected = tester.widget<Icon>(find.byType(Icon));
    expect(selected.icon, Icons.home);
    expect(selected.fill, isNull);

    await tester.pumpWidget(
      _wrap(
        const NavigationRailIcon(
          icon: Icons.home_outlined,
          selectedIcon: Icons.home,
          selected: false,
        ),
      ),
    );
    expect(tester.widget<Icon>(find.byType(Icon)).icon, Icons.home_outlined);
  });

  testWidgets('Lucide icons stay unchanged when no fill support', (
    WidgetTester tester,
  ) async {
    const IconData lucide = IconData(0xe000, fontFamily: 'Lucide');
    await tester.pumpWidget(
      _wrap(const NavigationRailIcon(icon: lucide, selected: true)),
    );
    final Icon selected = tester.widget<Icon>(find.byType(Icon));
    expect(selected.fill, isNull);
    expect(selected.icon, lucide);
  });
}
