import 'package:flutter/material.dart';

/// Reader color extension：阅读器沉浸底与弱化文字（恒暗，不跟壳层 seed）。
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

  /// 恒暗阅读器色；与应用明暗 / 配色方案无关。
  static const ReaderColorScheme immersive = ReaderColorScheme(
    readerBackground: Color(0xFF09090B),
    readerTextMuted: Color(0xB3FFFFFF),
    floatingUiBackground: Color(0xCC000000),
    activeButtonBg: Color(0xFF6EB3FF),
    sliderActive: Color(0xFF6EB3FF),
    sliderInactive: Color(0x33FFFFFF),
    readerTextIconPrimary: Color(0xE6FFFFFF),
    readerTextSecondary: Color(0x99FFFFFF),
    readerTextOnWhite: Color(0xFF000000),
    readerPanelBackground: Color(0xCC000000),
    readerPanelBorder: Color(0x14FFFFFF),
    readerPanelSubtle: Color(0x28000000),
    readerPanelSubtleBorder: Color(0x00FFFFFF),
    readerSliderOverlay: Color(0x336EB3FF),
  );

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
