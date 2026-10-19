import 'package:flutter/material.dart';

/// M3 [ColorScheme] role values before [HentaiColorScheme] semantic extensions.
@immutable
class AppCorePalette {
  const AppCorePalette({
    required this.primary,
    required this.onPrimary,
    required this.secondary,
    required this.onSecondary,
    required this.error,
    required this.onError,
    required this.surface,
    required this.onSurface,
    required this.surfaceContainer,
    required this.outline,
    required this.outlineVariant,
    required this.surfaceContainerHighest,
    required this.onSurfaceVariant,
    required this.primaryContainerBase,
    required this.onPrimaryContainer,
    required this.secondaryContainer,
    required this.onSecondaryContainer,
    required this.tertiary,
    required this.onTertiary,
    required this.tertiaryContainer,
    required this.onTertiaryContainer,
    required this.inverseSurface,
    required this.inversePrimary,
    required this.surfaceTint,
    required this.shadowAlpha,
  });

  final Color primary;
  final Color onPrimary;
  final Color secondary;
  final Color onSecondary;
  final Color error;
  final Color onError;
  final Color surface;
  final Color onSurface;
  final Color surfaceContainer;
  final Color outline;
  final Color outlineVariant;
  final Color surfaceContainerHighest;
  final Color onSurfaceVariant;
  final Color primaryContainerBase;
  final Color onPrimaryContainer;
  final Color secondaryContainer;
  final Color onSecondaryContainer;
  final Color tertiary;
  final Color onTertiary;
  final Color tertiaryContainer;
  final Color onTertiaryContainer;
  final Color inverseSurface;
  final Color inversePrimary;
  final Color surfaceTint;
  final int shadowAlpha;
}

const AppCorePalette _baseLightPalette = AppCorePalette(
  primary: Color(0xFF005FB8),
  onPrimary: Colors.white,
  secondary: Color(0xFF4CAF50),
  onSecondary: Colors.white,
  error: Color(0xFFB00020),
  onError: Colors.white,
  surface: Colors.white,
  onSurface: Color(0xFF111827),
  surfaceContainer: Color(0xFFF7F7F8),
  outline: Color(0xFFEDEFF2),
  outlineVariant: Color(0xFFD8DCE0),
  surfaceContainerHighest: Color(0xFFFCFCFD),
  onSurfaceVariant: Color(0xFF6B7280),
  primaryContainerBase: Color(0xFFECEEF2),
  onPrimaryContainer: Color(0xFF005FB8),
  secondaryContainer: Color(0xFFF0F2F5),
  onSecondaryContainer: Color(0xFF374151),
  tertiary: Color(0xFF6B7280),
  onTertiary: Colors.white,
  tertiaryContainer: Color(0xFFF0F2F5),
  onTertiaryContainer: Color(0xFF4B5563),
  inverseSurface: Color(0xFF2563EB),
  inversePrimary: Color(0xFFEF4444),
  surfaceTint: Color(0xFF005FB8),
  shadowAlpha: 6,
);

const AppCorePalette _baseDarkPalette = AppCorePalette(
  primary: Color(0xFF6EB3FF),
  onPrimary: Color(0xFF003258),
  secondary: Color(0xFF6FCF97),
  onSecondary: Color(0xFF00391C),
  error: Color(0xFFF44336),
  onError: Color(0xFF690005),
  surface: Color(0xFF1A1A1A),
  onSurface: Color(0xFFE5E5E5),
  surfaceContainer: Color(0xFF2D2D2D),
  outline: Color(0xFF404040),
  outlineVariant: Color(0xFF525252),
  surfaceContainerHighest: Color(0xFF363636),
  onSurfaceVariant: Color(0xFFB0B0B0),
  primaryContainerBase: Color(0xFF004578),
  onPrimaryContainer: Color(0xFFC8E4FF),
  secondaryContainer: Color(0xFF004D2A),
  onSecondaryContainer: Color(0xFF8FE8B0),
  tertiary: Color(0xFFB0B0B0),
  onTertiary: Color(0xFF2A2A2A),
  tertiaryContainer: Color(0xFF404040),
  onTertiaryContainer: Color(0xFFD0D0D0),
  inverseSurface: Color(0xFF6EB3FF),
  inversePrimary: Color(0xFF005FB8),
  surfaceTint: Color(0xFF1E1E1E),
  shadowAlpha: 80,
);

final ColorScheme _baseLightColorScheme = buildAppColorScheme(
  brightness: Brightness.light,
  palette: _baseLightPalette,
);

final ColorScheme _baseDarkColorScheme = buildAppColorScheme(
  brightness: Brightness.dark,
  palette: _baseDarkPalette,
);

ColorScheme buildBaseColorScheme(Brightness brightness) =>
    brightness == Brightness.dark ? _baseDarkColorScheme : _baseLightColorScheme;

ColorScheme buildAppColorScheme({
  required Brightness brightness,
  required AppCorePalette palette,
}) {
  final Color primaryContainer = brightness == Brightness.dark
      ? palette.primaryContainerBase
      : palette.primaryContainerBase.withAlpha(40);
  return ColorScheme(
    brightness: brightness,
    primary: palette.primary,
    onPrimary: palette.onPrimary,
    secondary: palette.secondary,
    onSecondary: palette.onSecondary,
    error: palette.error,
    onError: palette.onError,
    surface: palette.surface,
    onSurface: palette.onSurface,
    surfaceContainer: palette.surfaceContainer,
    outline: palette.outline,
    outlineVariant: palette.outlineVariant,
    surfaceContainerHighest: palette.surfaceContainerHighest,
    onSurfaceVariant: palette.onSurfaceVariant,
    primaryContainer: primaryContainer,
    onPrimaryContainer: palette.onPrimaryContainer,
    secondaryContainer: palette.secondaryContainer,
    onSecondaryContainer: palette.onSecondaryContainer,
    tertiary: palette.tertiary,
    onTertiary: palette.onTertiary,
    tertiaryContainer: palette.tertiaryContainer,
    onTertiaryContainer: palette.onTertiaryContainer,
    inverseSurface: palette.inverseSurface,
    inversePrimary: palette.inversePrimary,
    surfaceTint: palette.surfaceTint,
    shadow: Colors.black.withAlpha(palette.shadowAlpha),
  );
}
