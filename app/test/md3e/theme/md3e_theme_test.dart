import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/md3e/theme/md3e_theme.dart';
import 'package:material_expressive/theme.dart';

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
    final ExpressiveThemeData tokens = buildMd3eExpressiveThemeData();
    expect(tokens.materialTheme.colorScheme.brightness, Brightness.light);
    expect(
      tokens.materialTheme.textTheme.bodyLarge?.fontFamily,
      kMd3eAppFontFamily,
    );
  });
}
