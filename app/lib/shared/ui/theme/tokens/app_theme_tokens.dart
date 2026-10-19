import 'package:flutter/material.dart';
import 'package:hentai_library/shared/ui/theme/tokens/app_layout_tokens.dart';
import 'package:hentai_library/shared/ui/theme/tokens/app_radius_tokens.dart';
import 'package:hentai_library/shared/ui/theme/tokens/app_spacing_tokens.dart';
import 'package:hentai_library/shared/ui/theme/tokens/app_text_tokens.dart';
import 'package:theme_tailor_annotation/theme_tailor_annotation.dart';

part 'app_theme_tokens.tailor.dart';

@TailorMixin(themeGetter: ThemeGetter.none)
class AppThemeTokens extends ThemeExtension<AppThemeTokens>
    with _$AppThemeTokensTailorMixin {
  const AppThemeTokens({
    required this.text,
    required this.radius,
    required this.spacing,
    required this.layout,
  });

  final AppTextTokens text;
  final AppRadiusTokens radius;
  final AppSpacingTokens spacing;
  final AppLayoutTokens layout;

  static const AppThemeTokens shared = AppThemeTokens(
    text: AppTextTokens.shared,
    radius: AppRadiusTokens.shared,
    spacing: AppSpacingTokens.shared,
    layout: AppLayoutTokens.shared,
  );

  factory AppThemeTokens.light() => shared;

  factory AppThemeTokens.dark() => shared;
}
