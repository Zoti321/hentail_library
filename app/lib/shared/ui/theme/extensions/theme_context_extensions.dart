import 'package:flutter/material.dart';
import 'package:hentai_library/shared/ui/theme/color/hentai_color_scheme.dart';
import 'package:hentai_library/shared/ui/theme/tokens/app_motion_tokens.dart';
import 'package:hentai_library/shared/ui/theme/tokens/app_shadow_tokens.dart';
import 'package:hentai_library/shared/ui/theme/tokens/app_theme_tokens.dart';

extension ThemeTokensX on BuildContext {
  AppThemeTokens get tokens => Theme.of(this).extension<AppThemeTokens>()!;

  AppShadowTokens get shadows => Theme.of(this).extension<AppShadowTokens>()!;

  AppMotionTokens get motion => Theme.of(this).extension<AppMotionTokens>()!;

  HentaiColorScheme get hentai =>
      Theme.of(this).extension<HentaiColorScheme>()!;
}

extension DeprecatedHentaiColorSchemeOnColorScheme on ColorScheme {
  /// Prefer [ThemeTokensX.hentai] on [BuildContext]; registered on [ThemeData].
  @Deprecated(
    'Use context.hentai or Theme.of(context).extension<HentaiColorScheme>()',
  )
  HentaiColorScheme get hentai => brightness == Brightness.dark
      ? HentaiColorScheme.dark
      : HentaiColorScheme.light;
}
