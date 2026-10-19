import 'package:flutter/material.dart';
import 'package:theme_tailor_annotation/theme_tailor_annotation.dart';

part 'app_text_tokens.tailor.dart';

@TailorMixinComponent()
class AppTextTokens extends ThemeExtension<AppTextTokens>
    with _$AppTextTokensTailorMixin {
  const AppTextTokens({
    required this.labelXs,
    required this.bodySm,
    required this.bodyMd,
    required this.bodyLg,
    required this.titleSm,
    required this.titleMd,
    required this.titleLg,
  });

  final double labelXs;
  final double bodySm;
  final double bodyMd;
  final double bodyLg;
  final double titleSm;
  final double titleMd;
  final double titleLg;

  static const AppTextTokens shared = AppTextTokens(
    labelXs: 12,
    bodySm: 13,
    bodyMd: 14,
    bodyLg: 16,
    titleSm: 16,
    titleMd: 18,
    titleLg: 22,
  );
}
