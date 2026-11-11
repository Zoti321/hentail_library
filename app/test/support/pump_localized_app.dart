import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/design-system/design_system.dart';
import 'package:riverpod/misc.dart' show Override;

import 'localized_test_app.dart';

export 'localized_test_app.dart' show localizedTestAppConfig;
export 'test_view.dart' show configureTestView;

/// Builds a [MaterialApp] with product l10n + default light [buildAppTheme].
///
/// Use inside custom shells ([UncontrolledProviderScope], GoRouter, etc.) when
/// [pumpLocalizedApp] is not enough. Prefer [pumpLocalizedApp] for new tests.
MaterialApp buildLocalizedTestMaterialApp({
  required Widget home,
  Locale locale = const Locale('zh'),
  ThemeData? theme,
}) {
  final config = localizedTestAppConfig(locale: locale);
  return MaterialApp(
    locale: config.locale,
    localizationsDelegates: config.delegates,
    supportedLocales: config.locales,
    theme: theme ?? buildAppTheme(Brightness.light),
    home: home,
  );
}

/// Pumps a localized [MaterialApp] (optionally wrapped in [ProviderScope]).
///
/// Prefer this over copy-pasting MaterialApp + l10n delegates in new widget tests.
Future<void> pumpLocalizedApp(
  WidgetTester tester, {
  required Widget home,
  Locale locale = const Locale('zh'),
  ThemeData? theme,
  List<Override> overrides = const <Override>[],
  bool wrapProviderScope = false,
}) async {
  final config = localizedTestAppConfig(locale: locale);
  Widget app = MaterialApp(
    locale: config.locale,
    localizationsDelegates: config.delegates,
    supportedLocales: config.locales,
    theme: theme ?? buildAppTheme(Brightness.light),
    home: home,
  );
  if (wrapProviderScope || overrides.isNotEmpty) {
    app = ProviderScope(overrides: overrides, child: app);
  }
  await tester.pumpWidget(app);
}
