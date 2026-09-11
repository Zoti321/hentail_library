import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/ui/core/theme/theme.dart';
import 'package:riverpod/misc.dart' show Override;

import 'localized_test_app.dart';

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
