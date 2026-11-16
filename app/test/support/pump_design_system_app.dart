import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:hentai_library/design-system/design_system.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

Future<void> pumpDesignSystemApp(
  WidgetTester tester, {
  required Widget home,
  Locale locale = const Locale('zh'),
  Brightness brightness = Brightness.light,
  List<Locale> supportedLocales = const <Locale>[Locale('zh'), Locale('en')],
}) async {
  final theme = assembleAppTheme(brightness);
  await tester.pumpWidget(
    M3ETheme(
      data: theme.m3e,
      child: MaterialApp(
        locale: locale,
        supportedLocales: supportedLocales,
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        theme: theme.material,
        home: home,
      ),
    ),
  );
}
