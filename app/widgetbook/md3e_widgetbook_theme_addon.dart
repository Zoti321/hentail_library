import 'package:flutter/material.dart';
import 'package:hentai_library/md3e/theme/md3e_theme.dart';
import 'package:material_3_expressive/foundations/foundations.dart';
import 'package:widgetbook/widgetbook.dart';

/// Light / dark [M3EThemeData] switcher for MD3E Widgetbook previews.
ThemeAddon<M3EThemeData> buildMd3eWidgetbookThemeAddon() {
  final M3EThemeData light = buildMd3eThemeData(brightness: Brightness.light);
  final M3EThemeData dark = buildMd3eThemeData(brightness: Brightness.dark);

  return ThemeAddon<M3EThemeData>(
    initialTheme: WidgetbookTheme<M3EThemeData>(name: 'Light', data: light),
    themes: <WidgetbookTheme<M3EThemeData>>[
      WidgetbookTheme<M3EThemeData>(name: 'Light', data: light),
      WidgetbookTheme<M3EThemeData>(name: 'Dark', data: dark),
    ],
    themeBuilder: (
      BuildContext context,
      M3EThemeData m3e,
      Widget child,
    ) {
      final Brightness brightness = m3e.colorScheme.brightness;
      return M3ETheme(
        data: m3e,
        child: Theme(
          data: buildMd3eMaterialTheme(brightness, m3e: m3e),
          child: ColoredBox(
            color: m3e.colorScheme.surface,
            child: child,
          ),
        ),
      );
    },
  );
}
