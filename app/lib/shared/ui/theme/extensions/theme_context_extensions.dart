import 'package:flutter/material.dart';
import 'package:hentai_library/shared/ui/theme/color/reader_color_scheme.dart';
import 'package:hentai_library/shared/ui/theme/tokens/app_motion_tokens.dart';
import 'package:hentai_library/shared/ui/theme/tokens/app_shadow_tokens.dart';
import 'package:hentai_library/shared/ui/theme/tokens/app_theme_tokens.dart';

extension ThemeDesignX on ThemeData {
  AppThemeTokens get tokens => extension<AppThemeTokens>()!;

  AppShadowTokens get shadows => extension<AppShadowTokens>()!;

  AppMotionTokens get motion => extension<AppMotionTokens>()!;

  ReaderColorScheme get reader => extension<ReaderColorScheme>()!;
}

extension ThemeTokensX on BuildContext {
  ThemeData get _theme => Theme.of(this);

  AppThemeTokens get tokens => _theme.tokens;

  AppShadowTokens get shadows => _theme.shadows;

  AppMotionTokens get motion => _theme.motion;

  ReaderColorScheme get reader => _theme.reader;
}
