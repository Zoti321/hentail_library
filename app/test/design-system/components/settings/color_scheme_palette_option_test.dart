import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/design-system/design_system.dart';
import 'package:material_3_expressive/components/lists/components/m3e_card_radius_motion.dart';

import '../../../support/pump_design_system_app.dart';

void main() {
  testWidgets('palette swatch Containers fill Expanded (not zero-size)', (
    WidgetTester tester,
  ) async {
    await pumpDesignSystemApp(
      tester,
      home: const Scaffold(
        body: Center(
          child: ColorSchemePaletteOption(
            seed: Colors.teal,
            label: 'Teal',
            selected: false,
          ),
        ),
      ),
    );

    final List<Size> sizes = tester
        .widgetList<Container>(
          find.descendant(
            of: find.byType(ClipOval),
            matching: find.byType(Container),
          ),
        )
        .map((Container c) {
          final Element el = tester.element(find.byWidget(c));
          return (el.renderObject! as RenderBox).size;
        })
        .toList();

    expect(sizes, hasLength(3));
    expect(sizes[0], const Size(50, 25));
    expect(sizes[1], const Size(25, 25));
    expect(sizes[2], const Size(25, 25));
  });

  testWidgets('selected option shows check icon', (WidgetTester tester) async {
    await pumpDesignSystemApp(
      tester,
      home: const Scaffold(
        body: Center(
          child: ColorSchemePaletteOption(
            seed: Colors.indigo,
            label: 'Indigo',
            selected: true,
            onTap: _noop,
          ),
        ),
      ),
    );

    expect(find.byIcon(Icons.check_rounded), findsOneWidget);
    expect(find.text('Indigo'), findsOneWidget);
  });

  testWidgets('press morphs card radius from rest to pressed', (
    WidgetTester tester,
  ) async {
    await pumpDesignSystemApp(
      tester,
      home: const Scaffold(
        body: Center(
          child: ColorSchemePaletteOption(
            seed: Colors.amber,
            label: '琥珀色',
            selected: false,
            onTap: _noop,
          ),
        ),
      ),
    );

    final Finder motion = find.byType(M3ECardRadiusMotion);
    expect(
      tester.widget<M3ECardRadiusMotion>(motion).radius,
      const BorderRadius.all(
        Radius.circular(ColorSchemePaletteOption.restRadius),
      ),
    );

    final TestGesture gesture = await tester.startGesture(
      tester.getCenter(find.byType(ClipRRect)),
    );
    await tester.pump();

    expect(
      tester.widget<M3ECardRadiusMotion>(motion).radius,
      const BorderRadius.all(
        Radius.circular(ColorSchemePaletteOption.pressedRadius),
      ),
    );

    await gesture.up();
    await tester.pumpAndSettle();
    expect(
      tester.widget<M3ECardRadiusMotion>(motion).radius,
      const BorderRadius.all(
        Radius.circular(ColorSchemePaletteOption.restRadius),
      ),
    );
  });
}

void _noop() {}
