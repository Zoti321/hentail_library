part of 'theme.dart';

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

@immutable
class HentaiColorScheme {
  static const _baseLightPalette = _FluentCorePalette(
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

  static const _baseDarkPalette = _FluentCorePalette(
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

  static final ColorScheme _baseLightColorScheme = _buildFluentColorScheme(
    brightness: Brightness.light,
    palette: _baseLightPalette,
  );

  static final ColorScheme _baseDarkColorScheme = _buildFluentColorScheme(
    brightness: Brightness.dark,
    palette: _baseDarkPalette,
  );

  static ColorScheme buildBaseColorScheme(Brightness brightness) =>
      brightness == Brightness.dark ? _baseDarkColorScheme : _baseLightColorScheme;

  static ColorScheme _buildFluentColorScheme({
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

  const HentaiColorScheme({
    required this.hoverBackground,
    required this.cardHover,
    required this.overlayScrim,
    required this.inputBackground,
    required this.inputBackgroundDisabled,
    required this.subtleTagBackground,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.textPlaceholder,
    required this.textDisabled,
    required this.iconDefault,
    required this.iconSecondary,
    required this.borderSubtle,
    required this.borderMedium,
    required this.borderStrong,
    required this.inputBorder,
    required this.inputBorderActive,
    required this.cardShadow,
    required this.cardShadowHover,
    required this.imagePlaceholder,
    required this.imageFallback,
    required this.success,
    required this.warning,
    required this.winBackground,
    required this.winSurface,
    required this.sidebarBackground,
    required this.sidebarItemHoverBackground,
    required this.sidebarItemActiveBackground,
    required this.sidebarItemActiveBorder,
    required this.sidebarItemActiveShadowColor,
    required this.readerBackground,
    required this.floatingUiBackground,
    required this.activeButtonBg,
    required this.sliderActive,
    required this.sliderInactive,
    required this.readerTextMuted,
    required this.readerTextIconPrimary,
    required this.readerTextSecondary,
    required this.readerTextOnWhite,
    required this.readerPanelBackground,
    required this.readerPanelBorder,
    required this.readerPanelSubtle,
    required this.readerPanelSubtleBorder,
    required this.readerSliderOverlay,
    required this.contextMenuBackground,
    required this.contextMenuBorder,
    required this.contextMenuSeparator,
    required this.contextMenuText,
    required this.contextMenuMutedText,
    required this.contextMenuHover,
    required this.contextMenuDanger,
    required this.contextMenuShadow,
  });

  static const HentaiColorScheme light = HentaiColorScheme(
    hoverBackground: Color(0xFFFCFCFD),
    cardHover: Color(0xF5FFFFFF),
    overlayScrim: Color(0x32000000),
    inputBackground: Colors.white,
    inputBackgroundDisabled: Color(0xFFF6F7F8),
    subtleTagBackground: Color(0xFFF6F7F8),
    textPrimary: Color(0xFF111827),
    textSecondary: Color(0xFF374151),
    textTertiary: Color(0xFF6B7280),
    textPlaceholder: Color(0xFF9CA3AF),
    textDisabled: Color(0xFFD8DCE0),
    iconDefault: Color(0xFF6B7280),
    iconSecondary: Color(0xFF9CA3AF),
    borderSubtle: Color(0xFFEDEFF2),
    borderMedium: Color(0xFFD8DCE0),
    borderStrong: Color(0xFFA8ADB4),
    inputBorder: Color(0xFFEDEFF2),
    inputBorderActive: Color(0xFF005FB8),
    cardShadow: Color(0x0F000000),
    cardShadowHover: Color(0x20000000),
    imagePlaceholder: Color(0xFFECEEF1),
    imageFallback: Color(0xFFDDE1E6),
    success: Color(0xFF4CAF50),
    warning: Color(0xFFEF4444),
    winBackground: Color(0xFFF5F5F6),
    winSurface: Color.fromRGBO(245, 245, 247, 1),
    sidebarBackground: Color(0xFFFAFAFA),
    sidebarItemHoverBackground: Color(0xFFE8E8EC),
    sidebarItemActiveBackground: Colors.white,
    sidebarItemActiveBorder: Color(0xFFE4E7EC),
    sidebarItemActiveShadowColor: Color(0x1F000000),
    readerBackground: Color(0xFF09090B),
    floatingUiBackground: Color(0x99000000),
    activeButtonBg: Colors.white,
    sliderActive: Color(0xCCFFFFFF),
    sliderInactive: Color(0x33FFFFFF),
    readerTextMuted: Color(0x80FFFFFF),
    readerTextIconPrimary: Color(0xE6FFFFFF),
    readerTextSecondary: Color(0x99FFFFFF),
    readerTextOnWhite: Color(0xFF000000),
    readerPanelBackground: Color(0x99000000),
    readerPanelBorder: Color(0xCCFFFFFF),
    readerPanelSubtle: Color(0x28000000),
    readerPanelSubtleBorder: Color(0x0DFFFFFF),
    readerSliderOverlay: Color(0x1AFFFFFF),
    contextMenuBackground: Color(0xFFFFFFFF),
    contextMenuBorder: Color(0xFFD0D7DE),
    contextMenuSeparator: Color(0xFFD8DEE4),
    contextMenuText: Color(0xFF24292F),
    contextMenuMutedText: Color(0xFF57606A),
    contextMenuHover: Color(0xFFEAEFF4),
    contextMenuDanger: Color(0xFFCF222E),
    contextMenuShadow: Color(0x29000000),
  );

  static const HentaiColorScheme dark = HentaiColorScheme(
    hoverBackground: Color(0xFF363636),
    cardHover: Color(0xF52D2D2D),
    overlayScrim: Color(0x6E000000),
    inputBackground: Color(0xFF2D2D2D),
    inputBackgroundDisabled: Color(0xFF252525),
    subtleTagBackground: Color(0xFF252525),
    textPrimary: Color(0xFFE5E5E5),
    textSecondary: Color(0xFFB0B0B0),
    textTertiary: Color(0xFF909090),
    textPlaceholder: Color(0xFF707070),
    textDisabled: Color(0xFF525252),
    iconDefault: Color(0xFFB0B0B0),
    iconSecondary: Color(0xFF909090),
    borderSubtle: Color(0xFF404040),
    borderMedium: Color(0xFF525252),
    borderStrong: Color(0xFF707070),
    inputBorder: Color(0xFF404040),
    inputBorderActive: Color(0xFF6EB3FF),
    cardShadow: Color(0x99000000),
    cardShadowHover: Color(0xE6000000),
    imagePlaceholder: Color(0xFF3A3A3A),
    imageFallback: Color(0xFF4A4A4A),
    success: Color(0xFF4CAF50),
    warning: Color(0xFFEF4444),
    winBackground: Color(0xFF1A1A1A),
    winSurface: Color.fromRGBO(45, 45, 47, 1),
    sidebarBackground: Color(0xFF202020),
    sidebarItemHoverBackground: Color(0xFF343434),
    sidebarItemActiveBackground: Color(0xFF323234),
    sidebarItemActiveBorder: Color(0xFF4A4A4C),
    sidebarItemActiveShadowColor: Color(0x8F000000),
    readerBackground: Color(0xFF09090B),
    floatingUiBackground: Color(0x99000000),
    activeButtonBg: Colors.white,
    sliderActive: Color(0xCCFFFFFF),
    sliderInactive: Color(0x33FFFFFF),
    readerTextMuted: Color(0x80FFFFFF),
    readerTextIconPrimary: Color(0xE6FFFFFF),
    readerTextSecondary: Color(0x99FFFFFF),
    readerTextOnWhite: Color(0xFF000000),
    readerPanelBackground: Color(0x99000000),
    readerPanelBorder: Color(0xCCFFFFFF),
    readerPanelSubtle: Color(0x28000000),
    readerPanelSubtleBorder: Color(0x0DFFFFFF),
    readerSliderOverlay: Color(0x1AFFFFFF),
    contextMenuBackground: Color(0xFF2D333B),
    contextMenuBorder: Color(0xFF444C56),
    contextMenuSeparator: Color(0xFF373E47),
    contextMenuText: Color(0xFFADBAC7),
    contextMenuMutedText: Color(0xFF768390),
    contextMenuHover: Color(0xFF3D444D),
    contextMenuDanger: Color(0xFFF47067),
    contextMenuShadow: Color(0x7A010409),
  );

  final Color hoverBackground;
  final Color cardHover;
  final Color overlayScrim;
  final Color inputBackground;
  final Color inputBackgroundDisabled;
  final Color subtleTagBackground;
  final Color textPrimary;
  final Color textSecondary;
  final Color textTertiary;
  final Color textPlaceholder;
  final Color textDisabled;
  final Color iconDefault;
  final Color iconSecondary;
  final Color borderSubtle;
  final Color borderMedium;
  final Color borderStrong;
  final Color inputBorder;
  final Color inputBorderActive;
  final Color cardShadow;
  final Color cardShadowHover;
  final Color imagePlaceholder;
  final Color imageFallback;
  final Color success;
  final Color warning;
  final Color winBackground;
  final Color winSurface;
  final Color sidebarBackground;
  final Color sidebarItemHoverBackground;
  final Color sidebarItemActiveBackground;
  final Color sidebarItemActiveBorder;
  final Color sidebarItemActiveShadowColor;
  final Color readerBackground;
  final Color floatingUiBackground;
  final Color activeButtonBg;
  final Color sliderActive;
  final Color sliderInactive;
  final Color readerTextMuted;
  final Color readerTextIconPrimary;
  final Color readerTextSecondary;
  final Color readerTextOnWhite;
  final Color readerPanelBackground;
  final Color readerPanelBorder;
  final Color readerPanelSubtle;
  final Color readerPanelSubtleBorder;
  final Color readerSliderOverlay;
  final Color contextMenuBackground;
  final Color contextMenuBorder;
  final Color contextMenuSeparator;
  final Color contextMenuText;
  final Color contextMenuMutedText;
  final Color contextMenuHover;
  final Color contextMenuDanger;
  final Color contextMenuShadow;
}

extension HentaiColorSchemeExtension on ColorScheme {
  HentaiColorScheme get hentai => brightness == Brightness.dark
      ? HentaiColorScheme.dark
      : HentaiColorScheme.light;
}
