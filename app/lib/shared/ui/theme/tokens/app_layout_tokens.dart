import 'package:flutter/material.dart';
import 'package:theme_tailor_annotation/theme_tailor_annotation.dart';

part 'app_layout_tokens.tailor.dart';

@TailorMixinComponent()
class AppLayoutTokens extends ThemeExtension<AppLayoutTokens>
    with _$AppLayoutTokensTailorMixin {
  const AppLayoutTokens({
    required this.contentHorizontalPadding,
    required this.contentVerticalPadding,
  });

  final double contentHorizontalPadding;
  final double contentVerticalPadding;

  static const AppLayoutTokens shared = AppLayoutTokens(
    contentHorizontalPadding: 48,
    contentVerticalPadding: 16,
  );

  EdgeInsets get contentAreaPadding => EdgeInsets.symmetric(
    horizontal: contentHorizontalPadding,
    vertical: contentVerticalPadding,
  );
}
