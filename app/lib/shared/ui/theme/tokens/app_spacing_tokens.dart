import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';
import 'package:theme_tailor_annotation/theme_tailor_annotation.dart';

part 'app_spacing_tokens.tailor.dart';

@TailorMixinComponent()
class AppSpacingTokens extends ThemeExtension<AppSpacingTokens>
    with _$AppSpacingTokensTailorMixin {
  const AppSpacingTokens({
    required this.xs,
    required this.sm,
    required this.md,
    required this.lg,
    required this.xl,
  });

  @override
  final double xs;
  @override
  final double sm;
  @override
  final double md;
  @override
  final double lg;
  @override
  final double xl;

  static const AppSpacingTokens shared = AppSpacingTokens(
    xs: 4,
    sm: 8,
    md: 12,
    lg: 16,
    xl: 20,
  );

  @override
  AppSpacingTokens lerp(
    covariant ThemeExtension<AppSpacingTokens>? other,
    double t,
  ) {
    if (other is! AppSpacingTokens) return this;
    return AppSpacingTokens(
      xs: lerpDouble(xs, other.xs, t)!,
      sm: lerpDouble(sm, other.sm, t)!,
      md: lerpDouble(md, other.md, t)!,
      lg: lerpDouble(lg, other.lg, t)!,
      xl: lerpDouble(xl, other.xl, t)!,
    );
  }
}
