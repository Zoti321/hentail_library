import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/shared/ui/theme/theme.dart';

void main() {
  group('buildAppTheme MD3E assembly', () {
    test('light primary matches brand seed blue', () {
      final ThemeData theme = buildAppTheme(Brightness.light);
      expect(theme.colorScheme.primary, kAppBrandSeedColor);
    });

    test('registers layout, semantic, shadow, and motion extensions', () {
      for (final Brightness brightness in <Brightness>[
        Brightness.light,
        Brightness.dark,
      ]) {
        final ThemeData theme = buildAppTheme(brightness);
        expect(theme.extension<AppThemeTokens>(), isNotNull);
        expect(theme.extension<HentaiColorScheme>(), isNotNull);
        expect(theme.extension<AppShadowTokens>(), isNotNull);
        expect(theme.extension<AppMotionTokens>(), isNotNull);
      }
    });
  });
}
