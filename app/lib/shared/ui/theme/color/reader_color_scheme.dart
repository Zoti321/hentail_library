import 'package:flutter/material.dart';

/// Reader color extension：阅读器沉浸底与弱化文字（恒暗底，不跟应用浅色主题变浅）。
///
/// 强调色跟随壳层 [ColorScheme]（暗色用 primary，浅色壳用 inversePrimary），
/// 保证在恒暗底上可读，并与当前配色 / 品牌 seed 同源。
@immutable
class ReaderColorScheme extends ThemeExtension<ReaderColorScheme> {
  const ReaderColorScheme({
    required this.readerBackground,
    required this.readerTextMuted,
    required this.floatingUiBackground,
    required this.activeButtonBg,
    required this.sliderActive,
    required this.sliderInactive,
    required this.readerTextIconPrimary,
    required this.readerTextSecondary,
    required this.readerTextOnWhite,
    required this.readerPanelBackground,
    required this.readerPanelBorder,
    required this.readerPanelSubtle,
    required this.readerPanelSubtleBorder,
    required this.readerSliderOverlay,
  });

  /// 恒暗阅读画布（不随 seed / 应用明暗改变）。
  static const Color immersiveBackground = Color(0xFF09090B);

  final Color readerBackground;
  final Color readerTextMuted;
  final Color floatingUiBackground;
  final Color activeButtonBg;
  final Color sliderActive;
  final Color sliderInactive;
  final Color readerTextIconPrimary;
  final Color readerTextSecondary;
  final Color readerTextOnWhite;
  final Color readerPanelBackground;
  final Color readerPanelBorder;
  final Color readerPanelSubtle;
  final Color readerPanelSubtleBorder;
  final Color readerSliderOverlay;

  /// 由壳层 [ColorScheme] 派生强调色；背景等沉浸底保持恒暗。
  factory ReaderColorScheme.immersiveFor(ColorScheme shell) {
    final Color accent = shell.brightness == Brightness.dark
        ? shell.primary
        : shell.inversePrimary;
    return ReaderColorScheme(
      readerBackground: immersiveBackground,
      readerTextMuted: const Color(0xB3FFFFFF),
      floatingUiBackground: const Color(0xCC000000),
      activeButtonBg: accent,
      sliderActive: accent,
      sliderInactive: const Color(0x33FFFFFF),
      readerTextIconPrimary: const Color(0xE6FFFFFF),
      readerTextSecondary: const Color(0x99FFFFFF),
      readerTextOnWhite: const Color(0xFF000000),
      readerPanelBackground: const Color(0xCC000000),
      readerPanelBorder: const Color(0x14FFFFFF),
      readerPanelSubtle: const Color(0x28000000),
      readerPanelSubtleBorder: const Color(0x00FFFFFF),
      readerSliderOverlay: accent.withValues(alpha: 0.2),
    );
  }

  @override
  ReaderColorScheme copyWith({
    Color? readerBackground,
    Color? readerTextMuted,
    Color? floatingUiBackground,
    Color? activeButtonBg,
    Color? sliderActive,
    Color? sliderInactive,
    Color? readerTextIconPrimary,
    Color? readerTextSecondary,
    Color? readerTextOnWhite,
    Color? readerPanelBackground,
    Color? readerPanelBorder,
    Color? readerPanelSubtle,
    Color? readerPanelSubtleBorder,
    Color? readerSliderOverlay,
  }) {
    return ReaderColorScheme(
      readerBackground: readerBackground ?? this.readerBackground,
      readerTextMuted: readerTextMuted ?? this.readerTextMuted,
      floatingUiBackground: floatingUiBackground ?? this.floatingUiBackground,
      activeButtonBg: activeButtonBg ?? this.activeButtonBg,
      sliderActive: sliderActive ?? this.sliderActive,
      sliderInactive: sliderInactive ?? this.sliderInactive,
      readerTextIconPrimary:
          readerTextIconPrimary ?? this.readerTextIconPrimary,
      readerTextSecondary: readerTextSecondary ?? this.readerTextSecondary,
      readerTextOnWhite: readerTextOnWhite ?? this.readerTextOnWhite,
      readerPanelBackground:
          readerPanelBackground ?? this.readerPanelBackground,
      readerPanelBorder: readerPanelBorder ?? this.readerPanelBorder,
      readerPanelSubtle: readerPanelSubtle ?? this.readerPanelSubtle,
      readerPanelSubtleBorder:
          readerPanelSubtleBorder ?? this.readerPanelSubtleBorder,
      readerSliderOverlay: readerSliderOverlay ?? this.readerSliderOverlay,
    );
  }

  @override
  ReaderColorScheme lerp(ThemeExtension<ReaderColorScheme>? other, double t) {
    if (other is! ReaderColorScheme) {
      return this;
    }
    return ReaderColorScheme(
      readerBackground: Color.lerp(readerBackground, other.readerBackground, t)!,
      readerTextMuted: Color.lerp(readerTextMuted, other.readerTextMuted, t)!,
      floatingUiBackground: Color.lerp(
        floatingUiBackground,
        other.floatingUiBackground,
        t,
      )!,
      activeButtonBg: Color.lerp(activeButtonBg, other.activeButtonBg, t)!,
      sliderActive: Color.lerp(sliderActive, other.sliderActive, t)!,
      sliderInactive: Color.lerp(sliderInactive, other.sliderInactive, t)!,
      readerTextIconPrimary: Color.lerp(
        readerTextIconPrimary,
        other.readerTextIconPrimary,
        t,
      )!,
      readerTextSecondary: Color.lerp(
        readerTextSecondary,
        other.readerTextSecondary,
        t,
      )!,
      readerTextOnWhite: Color.lerp(
        readerTextOnWhite,
        other.readerTextOnWhite,
        t,
      )!,
      readerPanelBackground: Color.lerp(
        readerPanelBackground,
        other.readerPanelBackground,
        t,
      )!,
      readerPanelBorder: Color.lerp(
        readerPanelBorder,
        other.readerPanelBorder,
        t,
      )!,
      readerPanelSubtle: Color.lerp(
        readerPanelSubtle,
        other.readerPanelSubtle,
        t,
      )!,
      readerPanelSubtleBorder: Color.lerp(
        readerPanelSubtleBorder,
        other.readerPanelSubtleBorder,
        t,
      )!,
      readerSliderOverlay: Color.lerp(
        readerSliderOverlay,
        other.readerSliderOverlay,
        t,
      )!,
    );
  }
}
