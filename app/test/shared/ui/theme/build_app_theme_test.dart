import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/shared/ui/theme/theme.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart' as material_ui;

void main() {
  group('buildAppTheme MD3E assembly', () {
    test('light primary uses fidelity seed scheme not default tonalSpot', () {
      final ThemeData theme = buildAppTheme(Brightness.light);
      final Color fidelityPrimary = material_ui.ColorScheme.fromSeed(
        seedColor: kBrandSeedColor,
        brightness: Brightness.light,
        dynamicSchemeVariant: material_ui.DynamicSchemeVariant.fidelity,
      ).primary;
      final Color tonalSpotPrimary = M3EColorScheme.fromSeed(
        kBrandSeedColor,
        brightness: Brightness.light,
      ).primary;
      expect(theme.colorScheme.primary, fidelityPrimary);
      expect(theme.colorScheme.primary, isNot(tonalSpotPrimary));
    });

    test('Material ThemeData primary matches M3ETheme assembly for same seed', () {
      final ThemeData theme = buildAppTheme(Brightness.light);
      final M3EThemeData m3e = buildAppM3eThemeData(Brightness.light);
      expect(theme.colorScheme.primary, m3e.colorScheme.primary);
    });

    test('registers layout, semantic, shadow, and motion extensions', () {
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
  });
}
