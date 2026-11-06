import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/shared/ui/theme/theme.dart';

void main() {
  group('Reader color extension contract', () {
    test('registers immersive reader extension', () {
      for (final Brightness brightness in <Brightness>[
        Brightness.light,
        Brightness.dark,
      ]) {
        final ThemeData theme = buildAppTheme(brightness);
        expect(theme.extension<ReaderColorScheme>(), isNotNull);
        expect(
          theme.extension<ReaderColorScheme>()!.readerBackground,
          ReaderColorScheme.immersive.readerBackground,
        );
      }
    });

    test('reader background stays dark across colorSchemeId', () {
      final Color brandBg = buildAppTheme(
        Brightness.light,
        colorSchemeId: 'brand',
      ).reader.readerBackground;
      final Color tealBg = buildAppTheme(
        Brightness.light,
        colorSchemeId: 'teal',
      ).reader.readerBackground;
      expect(brandBg, tealBg);
      expect(brandBg.computeLuminance(), lessThan(0.2));
    });

    test('shell primary still follows seed while reader does not', () {
      final ThemeData brand = buildAppTheme(
        Brightness.light,
        colorSchemeId: 'brand',
      );
      final ThemeData teal = buildAppTheme(
        Brightness.light,
        colorSchemeId: 'teal',
      );
      expect(teal.colorScheme.primary, isNot(brand.colorScheme.primary));
      expect(teal.reader.readerBackground, brand.reader.readerBackground);
    });
  });

  group('buildAppTheme extensions after semantic shrink', () {
    test('registers layout, reader, shadow, and motion extensions', () {
      for (final Brightness brightness in <Brightness>[
        Brightness.light,
        Brightness.dark,
      ]) {
        final ThemeData theme = buildAppTheme(brightness);
        expect(theme.extension<AppThemeTokens>(), isNotNull);
        expect(theme.extension<ReaderColorScheme>(), isNotNull);
        expect(theme.extension<AppShadowTokens>(), isNotNull);
        expect(theme.extension<AppMotionTokens>(), isNotNull);
      }
    });

    test('spacing and radius sample still matches tokens', () {
      final AppThemeTokens tokens = buildAppTheme(
        Brightness.light,
      ).extension<AppThemeTokens>()!;
      expect(tokens.spacing.md, 12);
      expect(tokens.spacing.xl, 20);
      expect(tokens.radius.sm, 6);
      expect(tokens.radius.pill, 999);
      expect(tokens.layout.contentHorizontalPadding, 48);
    });
  });
}
