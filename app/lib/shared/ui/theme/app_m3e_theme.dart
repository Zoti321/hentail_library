import 'package:flutter/material.dart';
import 'package:hentai_library/shared/ui/layout/breakpoints.dart';
import 'package:material_3_expressive/foundations/foundations.dart';
import 'package:material_ui/material_ui.dart' as material_ui;

/// App UI font ([pubspec.yaml] `MI_Sans_Regular`); aligned with production shell.
const String kAppFontFamily = 'MI_Sans_Regular';

/// MD3E default seed (Widgetbook Lab purple). Production uses the same seed.
const Color kLabSeedColor = Color(0xFF6750A4);

/// Tone-based color system：seed → MCU fidelity scheme → M3E roles。
///
/// `M3EColorScheme.fromSeed` 不透传 variant，故经 material_ui
/// [ColorScheme.fromSeed] 薄封装后再 [M3EColorScheme.fromColorScheme]。
M3EColorScheme m3eColorSchemeForBrightness(
  Brightness brightness, {
  Color seed = kLabSeedColor,
}) {
  final material_ui.ColorScheme seeded = material_ui.ColorScheme.fromSeed(
    seedColor: seed,
    brightness: brightness,
    dynamicSchemeVariant: material_ui.DynamicSchemeVariant.fidelity,
  );
  return M3EColorScheme.fromColorScheme(seeded);
}

/// Applies app font to [M3EThemeData.fontFamily] and [M3EThemeData.typography].
M3EThemeData withAppFontFamily(M3EThemeData base) {
  return base.copyWith(
    fontFamily: kAppFontFamily,
    typography: base.typography.apply(fontFamily: kAppFontFamily),
  );
}

M3EThemeData applyShellNavRailOverrides(M3EThemeData base) {
  final M3EThemeData withFont = withAppFontFamily(base);
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

/// Expressive theme for app shell and MD3E widgets (seed + nav-rail metrics).
M3EThemeData buildAppM3eThemeData(
  Brightness brightness, {
  Color seed = kLabSeedColor,
}) {
  final M3EThemeData base = M3EThemeData(
    colorScheme: m3eColorSchemeForBrightness(brightness, seed: seed),
  );
  final M3EColorScheme colors = base.colorScheme;
  return applyShellNavRailOverrides(
    base.copyWith(
      // 与 [Breakpoints.expanded] 对齐：宽度 < 840 时 M3EDialog.showAdaptive 全屏，否则基础弹窗。
      // 基础弹窗容器默认 surfaceContainerHigh；改为 surface，与壳层画布 /
      // list-detail SharedAxis fillColor 一致（设置页同色）。
      dialogTheme: base.dialogTheme.copyWith(
        compactBreakpoint: Breakpoints.expanded,
        appearance: base.dialogTheme.appearance.copyWith(
          containerColor: colors.surface,
        ),
      ),
    ),
  );
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

/// Flutter [ThemeData] for legacy widgets alongside [M3ETheme] (overlays, dialogs).
ThemeData buildMaterialTheme(Brightness brightness, {M3EThemeData? m3e}) {
  final M3EThemeData resolved = m3e ?? buildAppM3eThemeData(brightness);
  return ThemeData(
    useMaterial3: true,
    fontFamily: kAppFontFamily,
    colorScheme: flutterColorSchemeFromM3e(resolved.colorScheme),
  );
}
