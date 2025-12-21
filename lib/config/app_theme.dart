import 'package:flutter/material.dart';
import 'package:hentai_library/config/app_fluent_color_scheme.dart';
import 'package:hentai_library/core/util/utils.dart';

ThemeData buildAppTheme(Color color, Brightness brightness) {
  final ColorScheme colorScheme = appFluentColorScheme(brightness);

  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    splashFactory: NoSplash.splashFactory,
    highlightColor: Colors.transparent,
    visualDensity: VisualDensity.adaptivePlatformDensity,
    fontFamily: 'MI_Sans_Regular',
    appBarTheme: _buildAppBarThemeData(colorScheme),
    navigationRailTheme: _buildNavRailThemeData(colorScheme),
    inputDecorationTheme: InputDecorationTheme(hintMaxLines: 1),
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        TargetPlatform.windows: FadeForwardsPageTransitionsBuilder(),
        TargetPlatform.macOS: ZoomPageTransitionsBuilder(),
      },
    ),
  );
}

AppBarTheme _buildAppBarThemeData(ColorScheme colorScheme) {
  return isDesktop
      ? AppBarTheme(
          surfaceTintColor: Colors.transparent,
          backgroundColor: colorScheme.surface,
          scrolledUnderElevation: 0.0,
        )
      : AppBarTheme();
}

NavigationRailThemeData _buildNavRailThemeData(ColorScheme colorScheme) {
  return NavigationRailThemeData(
    labelType: NavigationRailLabelType.all,
    backgroundColor: colorScheme.surface,
    useIndicator: true,
  );
}
