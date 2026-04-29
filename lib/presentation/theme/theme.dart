import 'package:flutter/material.dart';
import 'package:hentai_library/core/util/utils.dart';

part 'theme_layout_tokens.dart';
part 'theme_typography_tokens.dart';
part 'theme_visual_tokens.dart';

ThemeData buildAppTheme(Brightness brightness) {
  final colorScheme = appFluentColorScheme(brightness);
  final tokens = brightness == Brightness.dark
      ? AppThemeTokens.dark()
      : AppThemeTokens.light();
  final RoundedRectangleBorder buttonShape = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(tokens.radius.md),
  );

  var themeData = ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: colorScheme.surface,
    canvasColor: colorScheme.surface,
    dividerColor: colorScheme.outlineVariant,
    splashFactory: NoSplash.splashFactory,
    highlightColor: Colors.transparent,
    visualDensity: VisualDensity.adaptivePlatformDensity,
    fontFamily: 'MI_Sans_Regular',
    appBarTheme: _buildAppBarThemeData(colorScheme),
    navigationRailTheme: _buildNavRailThemeData(colorScheme),
    scrollbarTheme: _buildScrollbarTheme(colorScheme),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(shape: buttonShape),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(shape: buttonShape),
    ),
    inputDecorationTheme: const InputDecorationTheme(hintMaxLines: 1),
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        TargetPlatform.windows: FadeForwardsPageTransitionsBuilder(),
        TargetPlatform.macOS: ZoomPageTransitionsBuilder(),
      },
    ),
    extensions: [tokens],
  );
  return themeData;
}

ScrollbarThemeData _buildScrollbarTheme(ColorScheme colorScheme) {
  return ScrollbarThemeData(
    thumbVisibility: WidgetStateProperty.all(false),
    thickness: WidgetStateProperty.all(4),
    mainAxisMargin: 10,
    crossAxisMargin: 3,
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
  );
}

AppBarTheme _buildAppBarThemeData(ColorScheme colorScheme) {
  return isDesktop
      ? AppBarTheme(
          surfaceTintColor: Colors.transparent,
          backgroundColor: colorScheme.surface,
          scrolledUnderElevation: 0.0,
        )
      : const AppBarTheme();
}

NavigationRailThemeData _buildNavRailThemeData(ColorScheme colorScheme) {
  return NavigationRailThemeData(
    labelType: NavigationRailLabelType.all,
    backgroundColor: colorScheme.surface,
    useIndicator: true,
  );
}
