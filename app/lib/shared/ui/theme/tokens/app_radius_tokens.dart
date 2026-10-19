import 'package:flutter/material.dart';
import 'package:theme_tailor_annotation/theme_tailor_annotation.dart';

part 'app_radius_tokens.tailor.dart';

@TailorMixinComponent()
class AppRadiusTokens extends ThemeExtension<AppRadiusTokens>
    with _$AppRadiusTokensTailorMixin {
  const AppRadiusTokens({
    required this.xs,
    required this.sm,
    required this.md,
    required this.lg,
    required this.pill,
  });

  final double xs;
  final double sm;
  final double md;
  final double lg;
  final double pill;

  static const AppRadiusTokens shared = AppRadiusTokens(
    xs: 4,
    sm: 6,
    md: 8,
    lg: 12,
    pill: 999,
  );
}
