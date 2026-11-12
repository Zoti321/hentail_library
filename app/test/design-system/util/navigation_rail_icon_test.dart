import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/shared/ui/widgets/desktop/navigation_rail_icon.dart';
import 'package:material_symbols_icons/symbols.dart';

void main() {
  test(
    'Material Symbols use fill when selected and icon matches selectedIcon',
    () {
      final Widget selected = navigationRailIconWidget(
        icon: Symbols.home,
        selectedIcon: Symbols.home,
        selected: true,
      );
      final Icon icon = selected as Icon;
      expect(icon.fill, 1);

      final Widget unselected = navigationRailIconWidget(
        icon: Symbols.home,
        selectedIcon: Symbols.home,
        selected: false,
      );
      expect((unselected as Icon).fill, 0);
    },
  );

  test('explicit outlined/filled pair ignores fill axis', () {
    final Widget selected = navigationRailIconWidget(
      icon: Icons.home_outlined,
      selectedIcon: Icons.home,
      selected: true,
    );
    expect((selected as Icon).icon, Icons.home);
    expect(selected.fill, isNull);

    final Widget unselected = navigationRailIconWidget(
      icon: Icons.home_outlined,
      selectedIcon: Icons.home,
      selected: false,
    );
    expect((unselected as Icon).icon, Icons.home_outlined);
  });

  test('Lucide icons stay unchanged when no fill support', () {
    const IconData lucide = IconData(0xe000, fontFamily: 'Lucide');
    final Widget selected = navigationRailIconWidget(
      icon: lucide,
      selectedIcon: lucide,
      selected: true,
    );
    expect((selected as Icon).fill, isNull);
    expect(selected.icon, lucide);
  });
}
