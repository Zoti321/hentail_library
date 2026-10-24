import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hentai_library/shared/ui/motion/desktop_page_transition.dart';
import 'package:hentai_library/shared/ui/theme/color/app_color_scheme.dart';
import 'package:hentai_library/shared/ui/theme/color/app_shadow_palette.dart';
import 'package:hentai_library/shared/ui/theme/color/hentai_color_scheme.dart';
import 'package:hentai_library/shared/ui/theme/tokens/app_motion_tokens.dart';
import 'package:hentai_library/shared/ui/theme/tokens/app_shadow_tokens.dart';
import 'package:hentai_library/shared/ui/theme/tokens/app_theme_tokens.dart';

export 'package:hentai_library/shared/ui/theme/color/app_color_scheme.dart';
export 'package:hentai_library/shared/ui/theme/color/app_shadow_palette.dart';
export 'package:hentai_library/shared/ui/theme/color/hentai_color_scheme.dart';
export 'package:hentai_library/shared/ui/theme/extensions/theme_context_extensions.dart';
export 'package:hentai_library/shared/ui/theme/tokens/app_layout_tokens.dart';
export 'package:hentai_library/shared/ui/theme/tokens/app_motion_tokens.dart';
export 'package:hentai_library/shared/ui/theme/tokens/app_radius_tokens.dart';
export 'package:hentai_library/shared/ui/theme/tokens/app_shadow_tokens.dart';
export 'package:hentai_library/shared/ui/theme/tokens/app_spacing_tokens.dart';
export 'package:hentai_library/shared/ui/theme/tokens/app_text_tokens.dart';
export 'package:hentai_library/shared/ui/theme/tokens/app_theme_tokens.dart';

/// Shell / theme-boundary system bar style for everyday browsing chrome.
SystemUiOverlayStyle appSystemUiOverlayStyle(ColorScheme colorScheme) {
  final bool isDark = colorScheme.brightness == Brightness.dark;
  final Brightness iconBrightness = isDark ? Brightness.light : Brightness.dark;
  return SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: iconBrightness,
    statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
    systemNavigationBarColor: colorScheme.surface,
    systemNavigationBarIconBrightness: iconBrightness,
    systemNavigationBarContrastEnforced: false,
  );
}

/// Single assembly entry for app [ThemeData] (light/dark).
ThemeData buildAppTheme(Brightness brightness) {
  final ColorScheme colorScheme = buildBaseColorScheme(brightness);
  final HentaiColorScheme semantic = HentaiColorScheme.forBrightness(
    brightness,
  );
  final AppThemeTokens tokens = brightness == Brightness.dark
      ? AppThemeTokens.dark()
      : AppThemeTokens.light();
  final AppShadowTokens shadows = AppShadowTokens.fromPalette(
    AppShadowPalette.forBrightness(brightness),
  );
  final AppMotionTokens motion = brightness == Brightness.dark
      ? AppMotionTokens.dark()
      : AppMotionTokens.light();
  final RoundedRectangleBorder buttonShape = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(tokens.radius.md),
  );

  return ThemeData(
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
        TargetPlatform.linux: DesktopFadeThroughPageTransitionsBuilder(),
        TargetPlatform.macOS: DesktopFadeThroughPageTransitionsBuilder(),
        TargetPlatform.windows: DesktopFadeThroughPageTransitionsBuilder(),
      },
    ),
    extensions: <ThemeExtension<dynamic>>[tokens, semantic, shadows, motion],
  );
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
  return AppBarTheme(
    surfaceTintColor: Colors.transparent,
    backgroundColor: colorScheme.surface,
    scrolledUnderElevation: 0.0,
    systemOverlayStyle: appSystemUiOverlayStyle(colorScheme),
  );
}

NavigationRailThemeData _buildNavRailThemeData(ColorScheme colorScheme) {
  return NavigationRailThemeData(
    labelType: NavigationRailLabelType.all,
    backgroundColor: colorScheme.surface,
    useIndicator: true,
  );
}
