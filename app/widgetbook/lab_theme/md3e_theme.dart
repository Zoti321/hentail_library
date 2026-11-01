import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:hentai_library/shared/ui/theme/app_m3e_theme.dart';
import 'package:material_3_expressive/foundations/foundations.dart';

export 'package:hentai_library/shared/ui/theme/app_m3e_theme.dart'
    show
        buildAppM3eThemeData,
        flutterColorSchemeFromM3e,
        kMd3eAppFontFamily,
        kMd3eLabSeedColor,
        md3eWithAppFontFamily;

M3EColorScheme _md3eColorSchemeFor({
  Object? dynamicSource,
  required Brightness brightness,
}) {
  if (dynamicSource != null) {
    final dynamic scheme = dynamicSource;
    final Color seed = scheme.primary as Color;
    final Brightness resolved = scheme.brightness as Brightness? ?? brightness;
    return M3EColorScheme.fromSeed(seed, brightness: resolved);
  }
  return m3eColorSchemeForBrightness(brightness);
}

M3EThemeData _applyMd3eLabOverrides(M3EThemeData base) =>
    applyMd3eShellNavRailOverrides(base);

/// Builds [M3EThemeData] for the MD3E lab (seed + optional OS dynamic color).
M3EThemeData buildMd3eThemeData({
  Object? lightDynamic,
  Object? darkDynamic,
  Brightness brightness = Brightness.light,
}) {
  final M3EColorScheme scheme = brightness == Brightness.dark
      ? _md3eColorSchemeFor(
          dynamicSource: darkDynamic,
          brightness: Brightness.dark,
        )
      : _md3eColorSchemeFor(
          dynamicSource: lightDynamic,
          brightness: Brightness.light,
        );

  return _applyMd3eLabOverrides(M3EThemeData(colorScheme: scheme));
}

/// Flutter [ThemeData] for [MaterialApp] / legacy widgets alongside [M3ETheme].
ThemeData buildMd3eMaterialTheme(Brightness brightness, {M3EThemeData? m3e}) {
  final M3EThemeData resolved =
      m3e ?? buildMd3eThemeData(brightness: brightness);
  return ThemeData(
    useMaterial3: true,
    fontFamily: kMd3eAppFontFamily,
    colorScheme: flutterColorSchemeFromM3e(resolved.colorScheme),
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
  )
  builder;

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
