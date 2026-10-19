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

  final double xs;
  final double sm;
  final double md;
  final double lg;
  final double xl;

  static const AppSpacingTokens shared = AppSpacingTokens(
    xs: 4,
    sm: 8,
    md: 12,
    lg: 16,
    xl: 20,
  );
}
