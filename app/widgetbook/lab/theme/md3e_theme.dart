import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:hentai_library/shared/ui/theme/theme.dart';
import 'package:material_3_expressive/foundations/foundations.dart';
import 'package:material_ui/material_ui.dart' as material_ui;

export 'package:hentai_library/shared/ui/theme/app_m3e_theme.dart'
    show
        buildAppM3eThemeData,
        flutterColorSchemeFromM3e,
        kAppFontFamily,
        kBrandSeedColor,
        withAppFontFamily;

Color _seedFromDynamic(Object? dynamicSource) {
  if (dynamicSource is material_ui.ColorScheme) {
    return dynamicSource.primary;
  }
  return kBrandSeedColor;
}

/// Lab / Widgetbook：与生产同一 [assembleAppTheme] 入口（fidelity Tone-based）。
M3EThemeData buildThemeData({
  Object? lightDynamic,
  Object? darkDynamic,
  Brightness brightness = Brightness.light,
}) {
  final Object? dynamicSource = brightness == Brightness.dark
      ? darkDynamic
      : lightDynamic;
  return assembleAppTheme(
    brightness,
    seed: _seedFromDynamic(dynamicSource),
  ).m3e;
}

/// Flutter [ThemeData] for [MaterialApp] / legacy widgets alongside [M3ETheme].
ThemeData buildMaterialTheme(Brightness brightness, {M3EThemeData? m3e}) {
  if (m3e != null) {
    return materialThemeFromM3e(m3e);
  }
  return assembleAppTheme(brightness).material;
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
      builder:
          (
            material_ui.ColorScheme? lightDynamic,
            material_ui.ColorScheme? darkDynamic,
          ) {
            final AssembledAppTheme light = assembleAppTheme(
              Brightness.light,
              seed: _seedFromDynamic(lightDynamic),
            );
            final AssembledAppTheme dark = assembleAppTheme(
              Brightness.dark,
              seed: _seedFromDynamic(darkDynamic),
            );
            return M3ETheme(
              data: light.m3e,
              child: builder(
                context,
                light.m3e,
                light.material,
                dark.material,
              ),
            );
          },
    );
  }
}

/// Wraps [child] with expressive tokens (no dynamic color; for tests and static previews).
class ThemeScope extends StatelessWidget {
  const ThemeScope({super.key, required this.child, this.m3e});

  final Widget child;
  final M3EThemeData? m3e;

  @override
  Widget build(BuildContext context) {
    final M3EThemeData data = m3e ?? buildThemeData();
    return M3ETheme(data: data, child: child);
  }
}
