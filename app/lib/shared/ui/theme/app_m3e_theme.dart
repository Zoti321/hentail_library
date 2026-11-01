import 'package:flutter/material.dart';
import 'package:hentai_library/shared/ui/theme/color/app_color_scheme.dart';
import 'package:material_3_expressive/foundations/foundations.dart';

/// Production brand seed (light primary); not M3 Lab purple.
const Color kAppBrandSeedColor = Color(0xFF005FB8);

/// App UI font ([pubspec.yaml] `MI_Sans_Regular`); aligned with production shell.
const String kMd3eAppFontFamily = 'MI_Sans_Regular';

/// Lab previews historically used M3 baseline purple; production uses [kAppBrandSeedColor].
const Color kMd3eLabSeedColor = kAppBrandSeedColor;

M3EColorScheme m3eColorSchemeForBrightness(
  Brightness brightness, {
  Color seed = kAppBrandSeedColor,
}) {
  return M3EColorScheme.fromSeed(seed, brightness: brightness);
}

/// Pins M3 primary roles to production [buildBaseColorScheme] while keeping MD3E surfaces.
M3EColorScheme applyBrandPrimaryToM3eScheme(M3EColorScheme scheme) {
  final ColorScheme brand = buildBaseColorScheme(scheme.brightness);
  return scheme.copyWith(
    primary: brand.primary,
    onPrimary: brand.onPrimary,
    primaryContainer: brand.primaryContainer,
    onPrimaryContainer: brand.onPrimaryContainer,
  );
}

/// Applies app font to [M3EThemeData.fontFamily] and [M3EThemeData.typography].
M3EThemeData md3eWithAppFontFamily(M3EThemeData base) {
  return base.copyWith(
    fontFamily: kMd3eAppFontFamily,
    typography: base.typography.apply(fontFamily: kMd3eAppFontFamily),
  );
}

M3EThemeData applyMd3eShellNavRailOverrides(M3EThemeData base) {
  final M3EThemeData withFont = md3eWithAppFontFamily(base);
  final M3EColorScheme colors = withFont.colorScheme;
  return withFont.copyWith(
    navigationRailTheme: withFont.navigationRailTheme.copyWith(
      collapsedWidth: 80,
      narrowCollapsedWidth: 80,
      expandedMinWidth: 256,
      expandedMaxWidth: 256,
      containerColor: colors.surfaceContainerLow,
      topSpace: 8,
      destinationTopPadding: 24,
      itemVerticalGap: 8,
      expandedItemGap: 8,
    ),
  );
}

/// Expressive theme for app shell and MD3E widgets (brand seed, nav-rail metrics).
M3EThemeData buildAppM3eThemeData(Brightness brightness) {
  final M3EColorScheme scheme = applyBrandPrimaryToM3eScheme(
    m3eColorSchemeForBrightness(brightness),
  );
  return applyMd3eShellNavRailOverrides(M3EThemeData(colorScheme: scheme));
}

ColorScheme flutterColorSchemeFromM3e(M3EColorScheme scheme) {
  return ColorScheme(
    brightness: scheme.brightness,
    primary: scheme.primary,
    onPrimary: scheme.onPrimary,
    primaryContainer: scheme.primaryContainer,
    onPrimaryContainer: scheme.onPrimaryContainer,
    secondary: scheme.secondary,
    onSecondary: scheme.onSecondary,
    secondaryContainer: scheme.secondaryContainer,
    onSecondaryContainer: scheme.onSecondaryContainer,
    tertiary: scheme.tertiary,
    onTertiary: scheme.onTertiary,
    tertiaryContainer: scheme.tertiaryContainer,
    onTertiaryContainer: scheme.onTertiaryContainer,
    error: scheme.error,
    onError: scheme.onError,
    errorContainer: scheme.errorContainer,
    onErrorContainer: scheme.onErrorContainer,
    surface: scheme.surface,
    onSurface: scheme.onSurface,
    onSurfaceVariant: scheme.onSurfaceVariant,
    outline: scheme.outline,
    outlineVariant: scheme.outlineVariant,
    shadow: scheme.shadow,
    scrim: scheme.scrim,
    inverseSurface: scheme.inverseSurface,
    onInverseSurface: scheme.onInverseSurface,
    inversePrimary: scheme.inversePrimary,
    surfaceTint: scheme.surfaceTint,
    surfaceContainerHighest: scheme.surfaceContainerHighest,
    surfaceContainerHigh: scheme.surfaceContainerHigh,
    surfaceContainer: scheme.surfaceContainer,
    surfaceContainerLow: scheme.surfaceContainerLow,
    surfaceContainerLowest: scheme.surfaceContainerLowest,
    surfaceDim: scheme.surfaceDim,
    surfaceBright: scheme.surfaceBright,
  );
}
