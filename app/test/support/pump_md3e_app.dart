import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/md3e/theme/md3e_theme.dart';
import 'package:material_3_expressive/foundations/foundations.dart';

import 'localized_test_app.dart';

/// Pumps [home] under MD3E expressive theme (static lab seed, no dynamic color).
Future<void> pumpMd3eApp(
  WidgetTester tester, {
  required Widget home,
  Locale locale = const Locale('zh'),
  Brightness brightness = Brightness.light,
}) async {
  final M3EThemeData m3e = buildMd3eThemeData(brightness: brightness);
  final ThemeData theme = buildMd3eMaterialTheme(brightness, m3e: m3e);
  final localized = localizedTestAppConfig(locale: locale);
  await tester.pumpWidget(
    Md3eThemeScope(
      m3e: m3e,
      child: MaterialApp(
        locale: localized.locale,
        localizationsDelegates: localized.delegates,
        supportedLocales: localized.locales,
        theme: theme,
        home: home,
      ),
    ),
  );
}
