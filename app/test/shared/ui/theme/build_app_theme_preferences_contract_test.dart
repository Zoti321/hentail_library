import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/shared/ui/theme/theme.dart';

void main() {
  group('buildAppTheme preference assembly contract (ADR-0032)', () {
    test('registers extensions for brand palette with dynamic color stub', () {
      for (final Brightness brightness in <Brightness>[
        Brightness.light,
        Brightness.dark,
      ]) {
        final ThemeData theme = buildAppTheme(
          brightness,
          colorSchemeId: 'brand',
          useDynamicColor: true,
        );
        expect(theme.extension<AppThemeTokens>(), isNotNull);
        expect(theme.extension<HentaiColorScheme>(), isNotNull);
        expect(theme.extension<AppShadowTokens>(), isNotNull);
        expect(theme.extension<AppMotionTokens>(), isNotNull);
      }
    });

    test('brand light and dark themes stay structurally aligned', () {
      final ThemeData light = buildAppTheme(
        Brightness.light,
        colorSchemeId: 'brand',
      );
      final ThemeData dark = buildAppTheme(
        Brightness.dark,
        colorSchemeId: 'brand',
      );
      expect(light.useMaterial3, isTrue);
      expect(dark.useMaterial3, isTrue);
      expect(light.extensions.length, dark.extensions.length);
    });

    test('rejects unknown colorSchemeId', () {
      expect(
        () => buildAppTheme(Brightness.light, colorSchemeId: 'unknown'),
        throwsAssertionError,
      );
    });
  });
}
