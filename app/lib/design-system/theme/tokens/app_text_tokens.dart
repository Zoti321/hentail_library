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

  @override
  final double labelXs;
  @override
  final double bodySm;
  @override
  final double bodyMd;
  @override
  final double bodyLg;
  @override
  final double titleSm;
  @override
  final double titleMd;
  @override
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
