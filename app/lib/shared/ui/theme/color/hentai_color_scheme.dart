import 'package:flutter/material.dart';
import 'package:theme_tailor_annotation/theme_tailor_annotation.dart';

part 'hentai_color_scheme.tailor.dart';

/// Semantic colors layered on top of M3 [ColorScheme] from [buildBaseColorScheme].
@TailorMixin(themeGetter: ThemeGetter.none)
class HentaiColorScheme extends ThemeExtension<HentaiColorScheme>
    with _$HentaiColorSchemeTailorMixin {
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
    required this.imagePlaceholder,
    required this.imageFallback,
    required this.success,
    required this.warning,
    required this.error,
    required this.destructive,
    required this.onDestructive,
    required this.serializationHiatus,
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
  });

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
  final Color imagePlaceholder;
  final Color imageFallback;
  final Color success;
  final Color warning;
  final Color error;

  /// Destructive action fill (delete / remove / clear confirms).
  final Color destructive;
  final Color onDestructive;
  final Color serializationHiatus;
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

  static const HentaiColorScheme light = HentaiColorScheme(
    hoverBackground: Color(0xFFFCFCFD),
    cardHover: Color(0xF5FFFFFF),
    overlayScrim: Color(0x66000000),
    inputBackground: Colors.white,
    inputBackgroundDisabled: Color(0xFFF6F7F8),
    subtleTagBackground: Color(0xFFF6F7F8),
    textPrimary: Color(0xFF111827),
    textSecondary: Color(0xFF374151),
    textTertiary: Color(0xFF6B7280),
    textPlaceholder: Color(0xFF6B7280),
    textDisabled: Color(0xFFD8DCE0),
    iconDefault: Color(0xFF6B7280),
    iconSecondary: Color(0xFF9CA3AF),
    borderSubtle: Color(0xFFEDEFF2),
    borderMedium: Color(0xFFD8DCE0),
    borderStrong: Color(0xFFA8ADB4),
    inputBorder: Color(0xFFEDEFF2),
    inputBorderActive: Color(0xFF005FB8),
    imagePlaceholder: Color(0xFFECEEF1),
    imageFallback: Color(0xFFDDE1E6),
    success: Color(0xFF4CAF50),
    warning: Color(0xFFF59E0B),
    error: Color(0xFFEF4444),
    destructive: Color(0xFFCF222E),
    onDestructive: Colors.white,
    serializationHiatus: Color(0xFFF59E0B),
    winBackground: Color(0xFFF5F5F6),
    winSurface: Color.fromRGBO(245, 245, 247, 1),
    sidebarBackground: Color(0xFFFAFAFA),
    sidebarItemHoverBackground: Color(0xFFE8E8EC),
    sidebarItemActiveBackground: Colors.white,
    sidebarItemActiveBorder: Color(0xFFE4E7EC),
    sidebarItemActiveShadowColor: Color(0x1F000000),
    readerBackground: Color(0xFF09090B),
    floatingUiBackground: Color(0xCC000000),
    activeButtonBg: Color(0xFF6EB3FF),
    sliderActive: Color(0xFF6EB3FF),
    sliderInactive: Color(0x33FFFFFF),
    readerTextMuted: Color(0xB3FFFFFF),
    readerTextIconPrimary: Color(0xE6FFFFFF),
    readerTextSecondary: Color(0x99FFFFFF),
    readerTextOnWhite: Color(0xFF000000),
    readerPanelBackground: Color(0xCC000000),
    readerPanelBorder: Color(0x14FFFFFF),
    readerPanelSubtle: Color(0x28000000),
    readerPanelSubtleBorder: Color(0x00FFFFFF),
    readerSliderOverlay: Color(0x336EB3FF),
    contextMenuBackground: Color(0xFFFFFFFF),
    contextMenuBorder: Color(0xFFD0D7DE),
    contextMenuSeparator: Color(0xFFD8DEE4),
    contextMenuText: Color(0xFF24292F),
    contextMenuMutedText: Color(0xFF57606A),
    contextMenuHover: Color(0xFFEAEFF4),
    contextMenuDanger: Color(0xFFCF222E),
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
    textTertiary: Color(0xFFB0B0B0),
    textPlaceholder: Color(0xFFA3A3A3),
    textDisabled: Color(0xFF737373),
    iconDefault: Color(0xFFB0B0B0),
    iconSecondary: Color(0xFFA3A3A3),
    borderSubtle: Color(0xFF404040),
    borderMedium: Color(0xFF525252),
    borderStrong: Color(0xFF707070),
    inputBorder: Color(0xFF404040),
    inputBorderActive: Color(0xFF6EB3FF),
    imagePlaceholder: Color(0xFF3A3A3A),
    imageFallback: Color(0xFF4A4A4A),
    success: Color(0xFF4CAF50),
    warning: Color(0xFFF59E0B),
    error: Color(0xFFEF4444),
    destructive: Color(0xFFF47067),
    onDestructive: Color(0xFF1A0505),
    serializationHiatus: Color(0xFFF59E0B),
    winBackground: Color(0xFF1A1A1A),
    winSurface: Color.fromRGBO(45, 45, 47, 1),
    sidebarBackground: Color(0xFF202020),
    sidebarItemHoverBackground: Color(0xFF343434),
    sidebarItemActiveBackground: Color(0xFF323234),
    sidebarItemActiveBorder: Color(0xFF4A4A4C),
    sidebarItemActiveShadowColor: Color(0x8F000000),
    readerBackground: Color(0xFF09090B),
    floatingUiBackground: Color(0xCC000000),
    activeButtonBg: Color(0xFF6EB3FF),
    sliderActive: Color(0xFF6EB3FF),
    sliderInactive: Color(0x33FFFFFF),
    readerTextMuted: Color(0xB3FFFFFF),
    readerTextIconPrimary: Color(0xE6FFFFFF),
    readerTextSecondary: Color(0x99FFFFFF),
    readerTextOnWhite: Color(0xFF000000),
    readerPanelBackground: Color(0xCC000000),
    readerPanelBorder: Color(0x14FFFFFF),
    readerPanelSubtle: Color(0x28000000),
    readerPanelSubtleBorder: Color(0x00FFFFFF),
    readerSliderOverlay: Color(0x336EB3FF),
    contextMenuBackground: Color(0xFF2D333B),
    contextMenuBorder: Color(0xFF444C56),
    contextMenuSeparator: Color(0xFF373E47),
    contextMenuText: Color(0xFFADBAC7),
    contextMenuMutedText: Color(0xFF768390),
    contextMenuHover: Color(0xFF3D444D),
    contextMenuDanger: Color(0xFFF47067),
  );

  static HentaiColorScheme forBrightness(Brightness brightness) =>
      brightness == Brightness.dark ? dark : light;
}
