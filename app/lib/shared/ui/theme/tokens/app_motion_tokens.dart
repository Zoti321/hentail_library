import 'package:flutter/material.dart';
import 'package:theme_tailor_annotation/theme_tailor_annotation.dart';

part 'app_motion_tokens.tailor.dart';

/// Named motion durations for shell / catalog interactions (180–220 ms family).
@TailorMixin(themeGetter: ThemeGetter.none)
class AppMotionTokens extends ThemeExtension<AppMotionTokens>
    with _$AppMotionTokensTailorMixin {
  const AppMotionTokens({
    required this.durationFast,
    required this.durationMedium,
  });

  final Duration durationFast;
  final Duration durationMedium;

  static const Curve standardCurve = Curves.easeOutCubic;

  static const AppMotionTokens shared = AppMotionTokens(
    durationFast: Duration(milliseconds: 180),
    durationMedium: Duration(milliseconds: 200),
  );

  factory AppMotionTokens.light() => shared;

  factory AppMotionTokens.dark() => shared;
}
