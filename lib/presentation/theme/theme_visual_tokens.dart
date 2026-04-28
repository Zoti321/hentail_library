part of 'theme.dart';

ColorScheme appFluentLightScheme = ColorScheme(
  brightness: Brightness.light,
  primary: const Color(0xFF005fb8),
  onPrimary: Colors.white,
  secondary: const Color(0xFF4CAF50),
  onSecondary: Colors.white,
  error: const Color(0xFFB00020),
  onError: Colors.white,
  surface: Colors.white,
  onSurface: const Color(0xFF111827),
  surfaceContainer: const Color(0xFFF7F7F8),
  outline: const Color(0xFFEDEFF2),
  outlineVariant: const Color(0xFFD8DCE0),
  surfaceContainerHighest: const Color(0xFFFCFCFD),
  onSurfaceVariant: const Color(0xFF6B7280),
  primaryContainer: const Color(0xFFECEEF2).withAlpha(40),
  onPrimaryContainer: const Color(0xFF005FB8),
  secondaryContainer: const Color(0xFFF0F2F5),
  onSecondaryContainer: const Color(0xFF374151),
  tertiary: const Color(0xFF6B7280),
  onTertiary: Colors.white,
  tertiaryContainer: const Color(0xFFF0F2F5),
  onTertiaryContainer: const Color(0xFF4B5563),
  inverseSurface: const Color(0xFF2563EB),
  inversePrimary: const Color(0xFFEF4444),
  surfaceTint: const Color(0xFF005FB8),
  shadow: Colors.black.withAlpha(6),
);

ColorScheme appFluentDarkScheme = ColorScheme(
  brightness: Brightness.dark,
  primary: const Color(0xFF6EB3FF),
  onPrimary: const Color(0xFF003258),
  secondary: const Color(0xFF6FCF97),
  onSecondary: const Color(0xFF00391C),
  error: const Color(0xFFF44336),
  onError: const Color(0xFF690005),
  surface: const Color(0xFF1A1A1A),
  onSurface: const Color(0xFFE5E5E5),
  surfaceContainer: const Color(0xFF2D2D2D),
  outline: const Color(0xFF404040),
  outlineVariant: const Color(0xFF525252),
  surfaceContainerHighest: const Color(0xFF363636),
  onSurfaceVariant: const Color(0xFFB0B0B0),
  primaryContainer: const Color(0xFF004578),
  onPrimaryContainer: const Color(0xFFC8E4FF),
  secondaryContainer: const Color(0xFF004D2A),
  onSecondaryContainer: const Color(0xFF8FE8B0),
  tertiary: const Color(0xFFB0B0B0),
  onTertiary: const Color(0xFF2A2A2A),
  tertiaryContainer: const Color(0xFF404040),
  onTertiaryContainer: const Color(0xFFD0D0D0),
  inverseSurface: const Color(0xFF6EB3FF),
  inversePrimary: const Color(0xFF005fb8),
  surfaceTint: const Color(0xFF1e1e1e),
  shadow: Colors.black.withAlpha(80),
);

ColorScheme appFluentColorScheme(Brightness brightness) =>
    brightness == Brightness.dark ? appFluentDarkScheme : appFluentLightScheme;

extension AppColorSchemeExtension on ColorScheme {
  Color get hoverBackground => brightness == Brightness.dark
      ? const Color(0xFF363636)
      : const Color(0xFFFCFCFD);
  Color get textPrimary => brightness == Brightness.dark
      ? const Color(0xFFE5E5E5)
      : const Color(0xFF111827);
  Color get textSecondary => brightness == Brightness.dark
      ? const Color(0xFFB0B0B0)
      : const Color(0xFF374151);
  Color get textTertiary => brightness == Brightness.dark
      ? const Color(0xFF909090)
      : const Color(0xFF6B7280);
  Color get textPlaceholder => brightness == Brightness.dark
      ? const Color(0xFF707070)
      : const Color(0xFF9CA3AF);
  Color get textDisabled => brightness == Brightness.dark
      ? const Color(0xFF525252)
      : const Color(0xFFD8DCE0);
  Color get primaryHover => brightness == Brightness.dark
      ? const Color(0xFF8FC4FF)
      : const Color(0xFF004585);
  Color get buttonPressed => brightness == Brightness.dark
      ? Colors.white.withAlpha(10)
      : Colors.black.withAlpha(10);
  Color get buttonRipple => brightness == Brightness.dark
      ? Colors.white.withAlpha(5)
      : Colors.black.withAlpha(5);
  Color get cardHover => brightness == Brightness.dark
      ? const Color(0xFF2D2D2D).withAlpha(245)
      : Colors.white.withAlpha(245);
  Color get cardShadow => brightness == Brightness.dark
      ? Colors.black.withAlpha(60)
      : Colors.black.withAlpha(6);
  Color get cardShadowHover => brightness == Brightness.dark
      ? Colors.black.withAlpha(90)
      : Colors.black.withAlpha(32);
  Color get imagePlaceholder => brightness == Brightness.dark
      ? const Color(0xFF3A3A3A)
      : const Color(0xFFECEEF1);
  Color get imageFallback => brightness == Brightness.dark
      ? const Color(0xFF4A4A4A)
      : const Color(0xFFDDE1E6);
  Color get overlayScrim => brightness == Brightness.dark
      ? Colors.black.withAlpha(110)
      : Colors.black.withAlpha(50);
  Color get iconDefault => brightness == Brightness.dark
      ? const Color(0xFFB0B0B0)
      : const Color(0xFF6B7280);
  Color get iconSecondary => brightness == Brightness.dark
      ? const Color(0xFF909090)
      : const Color(0xFF9CA3AF);
  Color get iconActive => brightness == Brightness.dark
      ? const Color(0xFF6EB3FF)
      : const Color(0xFF005FB8);
  Color get borderSubtle => brightness == Brightness.dark
      ? const Color(0xFF404040)
      : const Color(0xFFEDEFF2);
  Color get borderMedium => brightness == Brightness.dark
      ? const Color(0xFF525252)
      : const Color(0xFFD8DCE0);
  Color get borderStrong => brightness == Brightness.dark
      ? const Color(0xFF707070)
      : const Color(0xFFA8ADB4);
  Color get success => const Color(0xFF4CAF50);
  Color get warning => const Color(0xFFEF4444);
  Color get info => const Color(0xFF2563EB);
  Color get inputBorder => brightness == Brightness.dark
      ? const Color(0xFF404040)
      : const Color(0xFFEDEFF2);
  Color get inputBorderActive => brightness == Brightness.dark
      ? const Color(0xFF6EB3FF)
      : const Color(0xFF005FB8);
  Color get inputBackground =>
      brightness == Brightness.dark ? const Color(0xFF2D2D2D) : Colors.white;
  Color get inputBackgroundDisabled => brightness == Brightness.dark
      ? const Color(0xFF252525)
      : const Color(0xFFF6F7F8);
  Color get subtleTagBackground => brightness == Brightness.dark
      ? const Color(0xFF252525)
      : const Color(0xFFF6F7F8);
}

extension WinTheme on ColorScheme {
  Color get winBackground => brightness == Brightness.dark
      ? const Color(0xFF1A1A1A)
      : const Color(0xFFF5F5F6);
  Color get winForeground => brightness == Brightness.dark
      ? const Color(0xFFE5E5E5)
      : const Color(0xFF1A1A1A);
  Color get winBorder => brightness == Brightness.dark
      ? const Color(0xFF404040)
      : const Color(0xFFD6D9DD);
  Color get winShadow => brightness == Brightness.dark
      ? const Color(0xFF303030)
      : const Color(0xFFB8BCC2);
  Color get winSurface => brightness == Brightness.dark
      ? const Color.fromRGBO(45, 45, 47, 1)
      : const Color.fromRGBO(245, 245, 247, 1);
  Color get sidebarBackground => brightness == Brightness.dark
      ? const Color(0xFF202020)
      : const Color(0xFFFAFAFA);

  /// 侧栏导航项悬停：与 [sidebarBackground] 对比足够明显，避免沿用全局 [hoverBackground] 在浅色下几乎无差。
  Color get sidebarItemHoverBackground => brightness == Brightness.dark
      ? const Color(0xFF343434)
      : const Color(0xFFE8E8EC);

  /// 侧栏选中项：亮色表面，与 [sidebarBackground] 区分；层次靠 [sidebarItemActiveBorder] 与阴影。
  Color get sidebarItemActiveBackground =>
      brightness == Brightness.dark ? const Color(0xFF323234) : Colors.white;

  /// 侧栏选中项描边。
  Color get sidebarItemActiveBorder => brightness == Brightness.dark
      ? const Color(0xFF4A4A4C)
      : const Color(0xFFE4E7EC);

  /// 侧栏选中项阴影（与 [cardShadow] 同量级略加强，便于叠在侧栏底上）。
  Color get sidebarItemActiveShadowColor => brightness == Brightness.dark
      ? Colors.black.withAlpha(56)
      : Colors.black.withAlpha(12);

  /// 侧栏选中项左侧指示条，与 [ColorScheme.primary] 一致。
  Color get sidebarItemActiveIndicator => primary;
}

extension ReaderPageTheme on ColorScheme {
  Color get readerBackground => const Color(0xFF09090B);
  Color get floatingUiBackground => const Color(0x99000000);
  Color get floatingUiBorder => const Color(0x1AFFFFFF);
  Color get floatingUiDivider => const Color(0x1AFFFFFF);
  Color get readerTextIconPrimary => const Color(0xE6FFFFFF);
  Color get readerTextSecondary => const Color(0x99FFFFFF);
  Color get readerTextMuted => const Color(0x80FFFFFF);
  Color get readerTextOnWhite => const Color(0xFF000000);
  Color get activeButtonBg => const Color(0xFFFFFFFF);
  Color get hoverBg => const Color(0x1AFFFFFF);
  Color get secondaryContainerBg => const Color(0x66000000);
  Color get sliderActive => const Color(0xCCFFFFFF);
  Color get sliderInactive => const Color(0x33FFFFFF);
  Color get chapterEndDivider => const Color(0xFF27272A);
  Color get chapterEndHintText => const Color(0xFF71717A);
  Color get readerPanelBackground => const Color(0x99000000);
  Color get readerPanelBorder => const Color(0xCCFFFFFF);
  Color get readerPanelSubtle => const Color(0x28000000);
  Color get readerPanelSubtleBorder => const Color(0x0DFFFFFF);
  Color get readerSliderOverlay => const Color(0x1AFFFFFF);
}
