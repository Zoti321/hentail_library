import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:material_3_expressive/foundations/foundations.dart';

/// Lab default seed (M3 baseline purple); not MASTER brand color yet.
const Color kMd3eLabSeedColor = Color(0xFF6750A4);

/// App UI font ([pubspec.yaml] `MI_Sans_Regular`); aligned with production shell.
const String kMd3eAppFontFamily = 'MI_Sans_Regular';

M3EColorScheme _md3eColorSchemeFor({
  Object? dynamicSource,
  required Brightness brightness,
}) {
  if (dynamicSource != null) {
    final dynamic scheme = dynamicSource;
    final Color seed = scheme.primary as Color;
    final Brightness resolved =
        scheme.brightness as Brightness? ?? brightness;
    return M3EColorScheme.fromSeed(seed, brightness: resolved);
  }
  return M3EColorScheme.fromSeed(kMd3eLabSeedColor, brightness: brightness);
}

M3EThemeData _applyMd3eLabOverrides(M3EThemeData base) {
  final M3EColorScheme colors = base.colorScheme;
  return base.copyWith(
    fontFamily: kMd3eAppFontFamily,
    navigationRailTheme: base.navigationRailTheme.copyWith(
      collapsedWidth: 80,
      narrowCollapsedWidth: 80,
      expandedMinWidth: 256,
      expandedMaxWidth: 256,
      containerColor: colors.surfaceContainerLow,
      // Default M3E gap is 4dp; MASTER shell needs visible separation between rows.
      itemVerticalGap: 8,
      expandedItemGap: 8,
    ),
  );
}

/// Builds [M3EThemeData] for the MD3E lab (seed + optional OS dynamic color).
M3EThemeData buildMd3eThemeData({
  Object? lightDynamic,
  Object? darkDynamic,
  Brightness brightness = Brightness.light,
}) {
  final M3EColorScheme scheme = brightness == Brightness.dark
      ? _md3eColorSchemeFor(dynamicSource: darkDynamic, brightness: Brightness.dark)
      : _md3eColorSchemeFor(
          dynamicSource: lightDynamic,
          brightness: Brightness.light,
        );

  return _applyMd3eLabOverrides(M3EThemeData(colorScheme: scheme));
}

ColorScheme _md3eFlutterColorScheme(M3EColorScheme scheme) {
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

/// Flutter [ThemeData] for [MaterialApp] / legacy widgets alongside [M3ETheme].
ThemeData buildMd3eMaterialTheme(
  Brightness brightness, {
  M3EThemeData? m3e,
}) {
  final M3EThemeData resolved =
      m3e ?? buildMd3eThemeData(brightness: brightness);
  return ThemeData(
    useMaterial3: true,
    fontFamily: kMd3eAppFontFamily,
    colorScheme: _md3eFlutterColorScheme(resolved.colorScheme),
  );
}

/// Provides [M3EThemeData] and respects platform dynamic color when present.
class Md3eDynamicTheme extends StatelessWidget {
  const Md3eDynamicTheme({super.key, required this.builder});

  final Widget Function(
    BuildContext context,
    M3EThemeData m3e,
    ThemeData theme,
    ThemeData darkTheme,
  ) builder;

  @override
  Widget build(BuildContext context) {
    return DynamicColorBuilder(
      builder: (Object? lightDynamic, Object? darkDynamic) {
        final M3EThemeData lightM3e = buildMd3eThemeData(
          lightDynamic: lightDynamic,
          darkDynamic: darkDynamic,
          brightness: Brightness.light,
        );
        final M3EThemeData darkM3e = buildMd3eThemeData(
          lightDynamic: lightDynamic,
          darkDynamic: darkDynamic,
          brightness: Brightness.dark,
        );
        return M3ETheme(
          data: lightM3e,
          child: builder(
            context,
            lightM3e,
            buildMd3eMaterialTheme(Brightness.light, m3e: lightM3e),
            buildMd3eMaterialTheme(Brightness.dark, m3e: darkM3e),
          ),
        );
      },
    );
  }
}

/// Wraps [child] with expressive tokens (no dynamic color; for tests and static previews).
class Md3eThemeScope extends StatelessWidget {
  const Md3eThemeScope({super.key, required this.child, this.m3e});

  final Widget child;
  final M3EThemeData? m3e;

  @override
  Widget build(BuildContext context) {
    final M3EThemeData data = m3e ?? buildMd3eThemeData();
    return M3ETheme(data: data, child: child);
  }
}
