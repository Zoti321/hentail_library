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
    scrollbarTheme: ScrollbarThemeData(
      thumbVisibility: WidgetStateProperty.all(true),
      thickness: WidgetStateProperty.all(6),
      radius: const Radius.circular(999),
      thumbColor: WidgetStateProperty.resolveWith<Color>((states) {
        final base = colorScheme.onSurfaceVariant;
        if (states.contains(WidgetState.dragged)) {
          return base.withOpacity(0.95);
        }
        if (states.contains(WidgetState.hovered)) {
          return base.withOpacity(0.85);
        }
        return base.withOpacity(0.65);
      }),
      trackColor: WidgetStateProperty.all(Colors.transparent),
      trackBorderColor: WidgetStateProperty.all(Colors.transparent),
    ),
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
