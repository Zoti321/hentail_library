import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/design-system/design_system.dart';
import 'package:material_ui/material_ui.dart' as material_ui;

void main() {
  group('buildAppTheme MD3E assembly', () {
    test('light primary uses tonalSpot + standard contrast', () {
      final ThemeData theme = buildAppTheme(Brightness.light);
      final Color standardPrimary = material_ui.ColorScheme.fromSeed(
        seedColor: kBrandSeedColor,
        brightness: Brightness.light,
        dynamicSchemeVariant: material_ui.DynamicSchemeVariant.tonalSpot,
        contrastLevel: material_ui.ContrastLevel.standard,
      ).primary;
      final Color fidelityPrimary = material_ui.ColorScheme.fromSeed(
        seedColor: kBrandSeedColor,
        brightness: Brightness.light,
        dynamicSchemeVariant: material_ui.DynamicSchemeVariant.fidelity,
        contrastLevel: material_ui.ContrastLevel.standard,
      ).primary;
      expect(theme.colorScheme.primary, standardPrimary);
      expect(theme.colorScheme.primary, isNot(fidelityPrimary));
    });

    test(
      'Material ThemeData primary matches M3ETheme assembly for same seed',
      () {
        final AssembledAppTheme assembled = assembleAppTheme(Brightness.light);
        expect(
          assembled.material.colorScheme.primary,
          assembled.m3e.colorScheme.primary,
        );
      },
    );

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
