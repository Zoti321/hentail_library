import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/design-system/design_system.dart';

void main() {
  group('buildAppTheme preference assembly contract (ADR-0032 / ADR-0037)', () {
    test('registers extensions for brand palette', () {
      for (final Brightness brightness in <Brightness>[
        Brightness.light,
        Brightness.dark,
      ]) {
        final ThemeData theme = buildAppTheme(
          brightness,
          colorSchemeId: 'brand',
        );
        expect(theme.extension<AppThemeTokens>(), isNotNull);
        expect(theme.extension<ReaderColorScheme>(), isNotNull);
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

    test('brand seed equals violet preference (product brand color)', () {
      expect(colorSchemeSeedForId('brand'), kBrandSeedColor);
      expect(colorSchemeSeedForId('violet'), kBrandSeedColor);
      final ThemeData brand = buildAppTheme(
        Brightness.light,
        colorSchemeId: 'brand',
      );
      final ThemeData violet = buildAppTheme(
        Brightness.light,
        colorSchemeId: 'violet',
      );
      expect(violet.colorScheme.primary, brand.colorScheme.primary);
    });

    test('non-brand colorSchemeId changes primary seed palette', () {
      final ThemeData brand = buildAppTheme(
        Brightness.light,
        colorSchemeId: 'brand',
      );
      final ThemeData teal = buildAppTheme(
        Brightness.light,
        colorSchemeId: 'teal',
      );
      expect(teal.colorScheme.primary, isNot(brand.colorScheme.primary));
    });

    test('explicit seed overrides fixed colorSchemeId', () {
      const Color overrideSeed = Color(0xFF006A6A);
      final ThemeData brand = buildAppTheme(
        Brightness.light,
        colorSchemeId: 'brand',
      );
      final ThemeData overridden = buildAppTheme(
        Brightness.light,
        colorSchemeId: 'brand',
        seed: overrideSeed,
      );
      expect(overridden.colorScheme.primary, isNot(brand.colorScheme.primary));
    });
  });

  group('resolveAppThemeSeed', () {
    test('uses fixed palette when dynamic color is off', () {
      const Color platformPrimary = Color(0xFF006A6A);
      expect(
        resolveAppThemeSeed(
          useDynamicColor: false,
          platformPrimary: platformPrimary,
          colorSchemeId: 'teal',
        ),
        colorSchemeSeedForId('teal'),
      );
    });

    test('uses platform primary when dynamic color is on', () {
      const Color platformPrimary = Color(0xFF006A6A);
      expect(
        resolveAppThemeSeed(
          useDynamicColor: true,
          platformPrimary: platformPrimary,
          colorSchemeId: 'brand',
        ),
        platformPrimary,
      );
    });

    test('falls back to fixed palette when platform primary is null', () {
      expect(
        resolveAppThemeSeed(
          useDynamicColor: true,
          platformPrimary: null,
          colorSchemeId: 'indigo',
        ),
        colorSchemeSeedForId('indigo'),
      );
    });
  });
}
