import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/shared/ui/theme/theme.dart';

void main() {
  group('HentaiColorScheme semantic colors', () {
    test('warning and error are distinct in light theme', () {
      final HentaiColorScheme h = buildAppTheme(
        Brightness.light,
      ).extension<HentaiColorScheme>()!;
      expect(h.warning, isNot(h.error));
      expect(h.serializationHiatus, h.warning);
    });

    test('warning and error are distinct in dark theme', () {
      final HentaiColorScheme h = buildAppTheme(
        Brightness.dark,
      ).extension<HentaiColorScheme>()!;
      expect(h.warning, isNot(h.error));
    });

    test('destructive matches contextMenuDanger and has onDestructive', () {
      final HentaiColorScheme light = buildAppTheme(
        Brightness.light,
      ).extension<HentaiColorScheme>()!;
      final HentaiColorScheme dark = buildAppTheme(
        Brightness.dark,
      ).extension<HentaiColorScheme>()!;

      expect(light.destructive, light.contextMenuDanger);
      expect(dark.destructive, dark.contextMenuDanger);
      expect(light.onDestructive, isNot(light.destructive));
      expect(dark.onDestructive, isNot(dark.destructive));
    });
  });

  group('buildAppTheme extensions', () {
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

    test('spacing and radius match design-system table (sample)', () {
      final AppThemeTokens tokens = buildAppTheme(
        Brightness.light,
      ).extension<AppThemeTokens>()!;
      expect(tokens.spacing.md, 12);
      expect(tokens.spacing.xl, 20);
      expect(tokens.radius.sm, 6);
      expect(tokens.radius.pill, 999);
      expect(tokens.layout.contentHorizontalPadding, 48);
    });

    test('shadow and motion presets are non-empty', () {
      final ThemeData theme = buildAppTheme(Brightness.light);
      final AppShadowTokens shadows = theme.extension<AppShadowTokens>()!;
      final AppMotionTokens motion = theme.extension<AppMotionTokens>()!;
      expect(shadows.catalogCard(highlighted: false), isNotEmpty);
      expect(shadows.elevatedSurface(isDark: false), isNotEmpty);
      expect(shadows.raisedPanel(), isNotEmpty);
      expect(motion.durationFast, const Duration(milliseconds: 180));
      expect(motion.durationMedium, const Duration(milliseconds: 200));
      expect(AppMotionTokens.standardCurve, Curves.easeOutCubic);
    });
  });

  group('ThemeExtension lerp', () {
    test('spacing tokens interpolate toward midpoint', () {
      const AppSpacingTokens a = AppSpacingTokens.shared;
      const AppSpacingTokens b = AppSpacingTokens(
        xs: 8,
        sm: 16,
        md: 24,
        lg: 32,
        xl: 40,
      );
      final AppSpacingTokens mid = a.lerp(b, 0.5) as AppSpacingTokens;
      expect(mid.md, 18);
      expect(mid.xs, 6);
    });
  });
}
