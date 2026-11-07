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

export 'package:hentai_library/shared/ui/theme/app_font.dart';
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

/// One seed → fidelity M3E + production [ThemeData]（ADR-0037 单次装配）。
final class AssembledAppTheme {
  const AssembledAppTheme({
    required this.seed,
    required this.m3e,
    required this.material,
  });

  final Color seed;
  final M3EThemeData m3e;
  final ThemeData material;
}

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

/// Resolves Tone-based seed for shell theme assembly (ADR-0037).
///
/// When [useDynamicColor] is on and [platformPrimary] is non-null (from
/// `dynamic_color` / system accent), use it as seed. Otherwise fall back to
/// the fixed [colorSchemeId] palette. Manual preference is preserved while
/// dynamic is on.
Color resolveAppThemeSeed({
  required bool useDynamicColor,
  Color? platformPrimary,
  String colorSchemeId = 'brand',
}) {
  if (useDynamicColor && platformPrimary != null) {
    return platformPrimary;
  }
  return colorSchemeSeedForId(colorSchemeId);
}

/// Assembles M3E + Material from one seed（`fromSeed` 只跑一次）.
AssembledAppTheme assembleAppTheme(
  Brightness brightness, {
  String colorSchemeId = 'brand',
  Color? seed,
  AppFontSpec font = const AppFontSpec(family: kAppFontFamily),
}) {
  final Color resolvedSeed = seed ?? colorSchemeSeedForId(colorSchemeId);
  final M3EThemeData m3e = buildAppM3eThemeData(
    brightness,
    seed: resolvedSeed,
    font: font,
  );
  return AssembledAppTheme(
    seed: resolvedSeed,
    m3e: m3e,
    material: materialThemeFromM3e(m3e, font: font),
  );
}

/// Builds production [ThemeData] from an already-assembled [M3EThemeData].
///
/// Does not re-run `ColorScheme.fromSeed`.
ThemeData materialThemeFromM3e(
  M3EThemeData m3e, {
  AppFontSpec font = const AppFontSpec(family: kAppFontFamily),
}) {
  final ColorScheme colorScheme = flutterColorSchemeFromM3e(m3e.colorScheme);
  final Brightness brightness = colorScheme.brightness;
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
  final String family = m3e.typeScale.bodyLarge.fontFamily ?? font.family;

  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: colorScheme.surface,
    canvasColor: colorScheme.surface,
    dividerColor: colorScheme.outlineVariant,
    splashFactory: NoSplash.splashFactory,
    highlightColor: Colors.transparent,
    visualDensity: VisualDensity.adaptivePlatformDensity,
    fontFamily: family,
    fontFamilyFallback: font.fallbacks,
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
      ReaderColorScheme.immersiveFor(colorScheme),
      shadows,
      motion,
    ],
  );
}

/// Single assembly entry for app [ThemeData] (light/dark).
///
/// [colorSchemeId] selects a fixed seed palette; [seed] overrides it when the
/// caller already resolved a dynamic or custom seed.
ThemeData buildAppTheme(
  Brightness brightness, {
  String colorSchemeId = 'brand',
  Color? seed,
  AppFontSpec font = const AppFontSpec(family: kAppFontFamily),
}) {
  return assembleAppTheme(
    brightness,
    colorSchemeId: colorSchemeId,
    seed: seed,
    font: font,
  ).material;
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
