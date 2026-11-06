import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_3_expressive/foundations/foundations.dart';
import 'package:hentai_library/shared/ui/motion/desktop_page_transition.dart';
import 'package:hentai_library/shared/ui/theme/color/app_shadow_palette.dart';
import 'package:hentai_library/shared/ui/theme/color/reader_color_scheme.dart';
import 'package:hentai_library/shared/ui/theme/tokens/app_motion_tokens.dart';
import 'package:hentai_library/shared/ui/theme/tokens/app_shadow_tokens.dart';
import 'package:hentai_library/shared/ui/theme/app_m3e_theme.dart';
import 'package:hentai_library/shared/ui/theme/color/app_color_scheme_seeds.dart';
import 'package:hentai_library/shared/ui/theme/tokens/app_theme_tokens.dart';

export 'package:hentai_library/shared/ui/theme/app_m3e_theme.dart';
export 'package:hentai_library/shared/ui/theme/color/app_color_scheme_seeds.dart';
export 'package:hentai_library/shared/ui/theme/color/app_shadow_palette.dart';
export 'package:hentai_library/shared/ui/theme/color/reader_color_scheme.dart';
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
///
/// [colorSchemeId] 选择固定 seed palette；[useDynamicColor] 仍为契约占位（ADR-0032）。
ThemeData buildAppTheme(
  Brightness brightness, {
  String colorSchemeId = 'brand',
  bool useDynamicColor = false,
}) {
  // 动态取色仍为契约占位：开启时不改变装配结果（ADR-0032）。
  assert(
    !useDynamicColor || colorSchemeId == 'brand',
    'useDynamicColor 尚未实现；仅 brand palette 可用',
  );
  final Color seed = colorSchemeSeedForId(colorSchemeId);
  final M3EThemeData m3e = buildAppM3eThemeData(brightness, seed: seed);
  final ColorScheme colorScheme = flutterColorSchemeFromM3e(m3e.colorScheme);
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
    extensions: <ThemeExtension<dynamic>>[
      tokens,
      ReaderColorScheme.immersive,
      shadows,
      motion,
    ],
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
