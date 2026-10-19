import 'package:flutter/material.dart';
import 'package:hentai_library/shared/ui/theme/color/hentai_color_scheme.dart';
import 'package:hentai_library/shared/ui/theme/tokens/app_motion_tokens.dart';
import 'package:hentai_library/shared/ui/theme/tokens/app_shadow_tokens.dart';
import 'package:hentai_library/shared/ui/theme/tokens/app_theme_tokens.dart';

extension ThemeDesignX on ThemeData {
  AppThemeTokens get tokens => extension<AppThemeTokens>()!;

  AppShadowTokens get shadows => extension<AppShadowTokens>()!;

  AppMotionTokens get motion => extension<AppMotionTokens>()!;

  HentaiColorScheme get hentai => extension<HentaiColorScheme>()!;
}

extension ThemeTokensX on BuildContext {
  ThemeData get _theme => Theme.of(this);

  AppThemeTokens get tokens => _theme.tokens;

  AppShadowTokens get shadows => _theme.shadows;

  AppMotionTokens get motion => _theme.motion;

  HentaiColorScheme get hentai => _theme.hentai;
}

extension DeprecatedHentaiColorSchemeOnColorScheme on ColorScheme {
  /// Prefer [ThemeTokensX.hentai] on [BuildContext]; registered on [ThemeData].
  @Deprecated('Use context.hentai or Theme.of(context).hentai')
  HentaiColorScheme get hentai => brightness == Brightness.dark
      ? HentaiColorScheme.dark
      : HentaiColorScheme.light;
}
