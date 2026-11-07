import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../widgetbook/lab/theme/md3e_theme.dart';

import 'package:material_3_expressive/foundations/foundations.dart';

import '../../support/pump_app.dart';

void main() {
  testWidgets('buildTheme pumps with primary from lab seed', (
    WidgetTester tester,
  ) async {
    await pumpApp(
      tester,
      home: Builder(
        builder: (BuildContext context) {
          final Color primary = Theme.of(context).colorScheme.primary;
          return Text('primary', style: TextStyle(color: primary));
        },
      ),
    );
    expect(find.text('primary'), findsOneWidget);
    final M3EThemeData m3e = buildThemeData();
    expect(m3e.colorScheme.brightness, Brightness.light);
    expect(
      buildMaterialTheme(
        Brightness.light,
        m3e: m3e,
      ).textTheme.bodyLarge?.fontFamily,
      kAppFontFamily,
    );
    expect(m3e.typeScale.bodyLarge.fontFamily, kAppFontFamily);
  });
}
