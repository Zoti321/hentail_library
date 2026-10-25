import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:material_expressive/theme.dart';

/// Lab default seed (M3 baseline purple); not MASTER brand color yet.
const Color kMd3eLabSeedColor = Color(0xFF6750A4);

/// App UI font ([pubspec.yaml] `MI_Sans_Regular`); aligned with production shell.
const String kMd3eAppFontFamily = 'MI_Sans_Regular';

/// Builds [ExpressiveThemeData] using material_expressive defaults, optionally
/// overlaying OS dynamic [ColorScheme]s when available.
/// Maps [dynamic_color] schemes (material_ui [ColorScheme] at runtime) to Flutter [ColorScheme].
ColorScheme? md3eFlutterColorSchemeFromDynamic(Object? source) {
  if (source == null) {
    return null;
  }
  final dynamic scheme = source;
  final Color primary = scheme.primary as Color;
  final Brightness brightness = scheme.brightness as Brightness;
  return ColorScheme.fromSeed(
    seedColor: primary,
    brightness: brightness,
  ).copyWith(
    primary: primary,
    onPrimary: scheme.onPrimary as Color,
    primaryContainer: scheme.primaryContainer as Color,
    onPrimaryContainer: scheme.onPrimaryContainer as Color,
    secondary: scheme.secondary as Color,
    onSecondary: scheme.onSecondary as Color,
    surface: scheme.surface as Color,
    onSurface: scheme.onSurface as Color,
    error: scheme.error as Color,
    onError: scheme.onError as Color,
  );
}

ExpressiveThemeData buildMd3eExpressiveThemeData({
  Object? lightDynamic,
  Object? darkDynamic,
}) {
  return ExpressiveTheme.fromSeed(
    seedColor: kMd3eLabSeedColor,
    fontFamily: kMd3eAppFontFamily,
    lightColorScheme: md3eFlutterColorSchemeFromDynamic(lightDynamic),
    darkColorScheme: md3eFlutterColorSchemeFromDynamic(darkDynamic),
  );
}

/// Resolves [ThemeData] for the given [brightness] from expressive tokens.
ThemeData buildMd3eTheme(
  Brightness brightness, {
  ExpressiveThemeData? expressive,
}) {
  final ExpressiveThemeData resolved =
      expressive ?? buildMd3eExpressiveThemeData();
  return brightness == Brightness.dark
      ? resolved.materialDarkTheme
      : resolved.materialTheme;
}

/// Provides [ExpressiveThemeData] and respects platform dynamic color when present.
class Md3eDynamicTheme extends StatelessWidget {
  const Md3eDynamicTheme({super.key, required this.builder});

  final Widget Function(
    BuildContext context,
    ExpressiveThemeData expressive,
    ThemeData theme,
    ThemeData darkTheme,
  ) builder;

  @override
  Widget build(BuildContext context) {
    return DynamicColorBuilder(
      builder: (Object? lightDynamic, Object? darkDynamic) {
        final ExpressiveThemeData expressive = buildMd3eExpressiveThemeData(
          lightDynamic: lightDynamic,
          darkDynamic: darkDynamic,
        );
        return ExpressiveThemeProvider(
          themeData: expressive,
          child: builder(
            context,
            expressive,
            expressive.materialTheme,
            expressive.materialDarkTheme,
          ),
        );
      },
    );
  }
}

/// Wraps [child] with expressive tokens (no dynamic color; for tests and static previews).
class Md3eThemeScope extends StatelessWidget {
  const Md3eThemeScope({super.key, required this.child, this.expressive});

  final Widget child;
  final ExpressiveThemeData? expressive;

  @override
  Widget build(BuildContext context) {
    final ExpressiveThemeData data =
        expressive ?? buildMd3eExpressiveThemeData();
    return ExpressiveThemeProvider(themeData: data, child: child);
  }
}
