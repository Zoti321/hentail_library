import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/md3e/theme/md3e_theme.dart';
import 'package:material_3_expressive/foundations/foundations.dart';

import '../../support/pump_md3e_app.dart';

void main() {
  testWidgets('buildMd3eTheme pumps with primary from lab seed', (
    WidgetTester tester,
  ) async {
    await pumpMd3eApp(
      tester,
      home: Builder(
        builder: (BuildContext context) {
          final Color primary = Theme.of(context).colorScheme.primary;
          return Text('primary', style: TextStyle(color: primary));
        },
      ),
    );
    expect(find.text('primary'), findsOneWidget);
    final M3EThemeData m3e = buildMd3eThemeData();
    expect(m3e.colorScheme.brightness, Brightness.light);
    expect(
      buildMd3eMaterialTheme(Brightness.light, m3e: m3e)
          .textTheme
          .bodyLarge
          ?.fontFamily,
      kMd3eAppFontFamily,
    );
    expect(m3e.typeScale.bodyLarge.fontFamily, kMd3eAppFontFamily);
  });
}
