part of 'theme.dart';

const _FluentCorePalette _lightPalette = _FluentCorePalette(
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

const _FluentCorePalette _darkPalette = _FluentCorePalette(
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

final ColorScheme appFluentLightScheme = _buildFluentColorScheme(
  brightness: Brightness.light,
  palette: _lightPalette,
);
final ColorScheme appFluentDarkScheme = _buildFluentColorScheme(
  brightness: Brightness.dark,
  palette: _darkPalette,
);

ColorScheme appFluentColorScheme(Brightness brightness) =>
    brightness == Brightness.dark ? appFluentDarkScheme : appFluentLightScheme;

ColorScheme _buildFluentColorScheme({
  required Brightness brightness,
  required _FluentCorePalette palette,
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

@immutable
class _FluentCorePalette {
  const _FluentCorePalette({
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

extension AppColorSchemeExtension on ColorScheme {
  bool get _isDark => brightness == Brightness.dark;

  /// Surface
  Color get hoverBackground =>
      _isDark ? const Color(0xFF363636) : const Color(0xFFFCFCFD);
  Color get cardHover => _isDark
      ? const Color(0xFF2D2D2D).withAlpha(245)
      : Colors.white.withAlpha(245);
  Color get overlayScrim =>
      _isDark ? Colors.black.withAlpha(110) : Colors.black.withAlpha(50);
  Color get inputBackground => _isDark ? const Color(0xFF2D2D2D) : Colors.white;
  Color get inputBackgroundDisabled =>
      _isDark ? const Color(0xFF252525) : const Color(0xFFF6F7F8);
  Color get subtleTagBackground =>
      _isDark ? const Color(0xFF252525) : const Color(0xFFF6F7F8);

  /// Text
  Color get textPrimary =>
      _isDark ? const Color(0xFFE5E5E5) : const Color(0xFF111827);
  Color get textSecondary =>
      _isDark ? const Color(0xFFB0B0B0) : const Color(0xFF374151);
  Color get textTertiary =>
      _isDark ? const Color(0xFF909090) : const Color(0xFF6B7280);
  Color get textPlaceholder =>
      _isDark ? const Color(0xFF707070) : const Color(0xFF9CA3AF);
  Color get textDisabled =>
      _isDark ? const Color(0xFF525252) : const Color(0xFFD8DCE0);

  /// Icon
  Color get iconDefault =>
      _isDark ? const Color(0xFFB0B0B0) : const Color(0xFF6B7280);
  Color get iconSecondary =>
      _isDark ? const Color(0xFF909090) : const Color(0xFF9CA3AF);
  Color get iconActive =>
      _isDark ? const Color(0xFF6EB3FF) : const Color(0xFF005FB8);

  /// Border
  Color get borderSubtle =>
      _isDark ? const Color(0xFF404040) : const Color(0xFFEDEFF2);
  Color get borderMedium =>
      _isDark ? const Color(0xFF525252) : const Color(0xFFD8DCE0);
  Color get borderStrong =>
      _isDark ? const Color(0xFF707070) : const Color(0xFFA8ADB4);
  Color get inputBorder =>
      _isDark ? const Color(0xFF404040) : const Color(0xFFEDEFF2);
  Color get inputBorderActive =>
      _isDark ? const Color(0xFF6EB3FF) : const Color(0xFF005FB8);

  /// Interaction
  Color get primaryHover =>
      _isDark ? const Color(0xFF8FC4FF) : const Color(0xFF004585);
  Color get buttonPressed =>
      _isDark ? Colors.white.withAlpha(10) : Colors.black.withAlpha(10);
  Color get buttonRipple =>
      _isDark ? Colors.white.withAlpha(5) : Colors.black.withAlpha(5);

  /// Shadow
  Color get cardShadow =>
      _isDark ? Colors.black.withAlpha(60) : Colors.black.withAlpha(6);
  Color get cardShadowHover =>
      _isDark ? Colors.black.withAlpha(90) : Colors.black.withAlpha(32);

  /// Media
  Color get imagePlaceholder =>
      _isDark ? const Color(0xFF3A3A3A) : const Color(0xFFECEEF1);
  Color get imageFallback =>
      _isDark ? const Color(0xFF4A4A4A) : const Color(0xFFDDE1E6);

  /// Feedback
  Color get success => const Color(0xFF4CAF50);
  Color get warning => const Color(0xFFEF4444);
  Color get info => const Color(0xFF2563EB);
}

extension WinTheme on ColorScheme {
  bool get _isDarkWin => brightness == Brightness.dark;

  /// Window chrome
  Color get winBackground =>
      _isDarkWin ? const Color(0xFF1A1A1A) : const Color(0xFFF5F5F6);
  Color get winForeground =>
      _isDarkWin ? const Color(0xFFE5E5E5) : const Color(0xFF1A1A1A);
  Color get winBorder =>
      _isDarkWin ? const Color(0xFF404040) : const Color(0xFFD6D9DD);
  Color get winShadow =>
      _isDarkWin ? const Color(0xFF303030) : const Color(0xFFB8BCC2);
  Color get winSurface => _isDarkWin
      ? const Color.fromRGBO(45, 45, 47, 1)
      : const Color.fromRGBO(245, 245, 247, 1);
  Color get sidebarBackground =>
      _isDarkWin ? const Color(0xFF202020) : const Color(0xFFFAFAFA);

  /// Sidebar interaction
  /// 侧栏导航项悬停：与 [sidebarBackground] 对比足够明显，避免沿用全局 [hoverBackground] 在浅色下几乎无差。
  Color get sidebarItemHoverBackground =>
      _isDarkWin ? const Color(0xFF343434) : const Color(0xFFE8E8EC);

  /// 侧栏选中项：亮色表面，与 [sidebarBackground] 区分；层次靠 [sidebarItemActiveBorder] 与阴影。
  Color get sidebarItemActiveBackground =>
      _isDarkWin ? const Color(0xFF323234) : Colors.white;

  /// 侧栏选中项描边。
  Color get sidebarItemActiveBorder =>
      _isDarkWin ? const Color(0xFF4A4A4C) : const Color(0xFFE4E7EC);

  /// 侧栏选中项阴影（与 [cardShadow] 同量级略加强，便于叠在侧栏底上）。
  Color get sidebarItemActiveShadowColor =>
      _isDarkWin ? Colors.black.withAlpha(56) : Colors.black.withAlpha(12);

  /// 侧栏选中项左侧指示条，与 [ColorScheme.primary] 一致。
  Color get sidebarItemActiveIndicator => primary;
}

extension ReaderPageTheme on ColorScheme {
  /// Reader canvas
  Color get readerBackground => const Color(0xFF09090B);

  /// Floating UI shell
  Color get floatingUiBackground => const Color(0x99000000);
  Color get floatingUiBorder => const Color(0x1AFFFFFF);
  Color get floatingUiDivider => const Color(0x1AFFFFFF);

  /// Reader typography and icon
  Color get readerTextIconPrimary => const Color(0xE6FFFFFF);
  Color get readerTextSecondary => const Color(0x99FFFFFF);
  Color get readerTextMuted => const Color(0x80FFFFFF);
  Color get readerTextOnWhite => const Color(0xFF000000);

  /// Button and interaction
  Color get activeButtonBg => const Color(0xFFFFFFFF);
  Color get hoverBg => const Color(0x1AFFFFFF);
  Color get secondaryContainerBg => const Color(0x66000000);

  /// Slider
  Color get sliderActive => const Color(0xCCFFFFFF);
  Color get sliderInactive => const Color(0x33FFFFFF);
  Color get readerSliderOverlay => const Color(0x1AFFFFFF);

  /// Chapter end
  Color get chapterEndDivider => const Color(0xFF27272A);
  Color get chapterEndHintText => const Color(0xFF71717A);

  /// Panel
  Color get readerPanelBackground => const Color(0x99000000);
  Color get readerPanelBorder => const Color(0xCCFFFFFF);
  Color get readerPanelSubtle => const Color(0x28000000);
  Color get readerPanelSubtleBorder => const Color(0x0DFFFFFF);
}
