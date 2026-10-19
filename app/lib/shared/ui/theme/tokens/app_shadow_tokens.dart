import 'package:flutter/material.dart';
import 'package:hentai_library/shared/ui/theme/color/hentai_color_scheme.dart';
import 'package:theme_tailor_annotation/theme_tailor_annotation.dart';

part 'app_shadow_tokens.tailor.dart';

/// Layered shadow presets; colors come from semantic palette at assembly time.
@TailorMixin(themeGetter: ThemeGetter.none)
class AppShadowTokens extends ThemeExtension<AppShadowTokens>
    with _$AppShadowTokensTailorMixin {
  const AppShadowTokens({
    required this.catalogCardRest,
    required this.catalogCardHover,
    required this.dialogPrimary,
    required this.dialogSecondary,
    required this.toastPrimary,
    required this.toastSecondary,
    required this.contextMenu,
  });

  final Color catalogCardRest;
  final Color catalogCardHover;
  final Color dialogPrimary;
  final Color dialogSecondary;
  final Color toastPrimary;
  final Color toastSecondary;
  final Color contextMenu;

  factory AppShadowTokens.fromSemantic(HentaiColorScheme semantic) {
    return AppShadowTokens(
      catalogCardRest: semantic.cardShadow,
      catalogCardHover: semantic.cardShadowHover,
      dialogPrimary: semantic.cardShadowHover,
      dialogSecondary: semantic.cardShadow,
      toastPrimary: semantic.cardShadowHover,
      toastSecondary: semantic.cardShadow,
      contextMenu: semantic.contextMenuShadow,
    );
  }

  List<BoxShadow> catalogCard({required bool highlighted}) {
    if (highlighted) {
      return [
        BoxShadow(
          color: catalogCardHover,
          blurRadius: 4,
          offset: const Offset(0, 2),
        ),
      ];
    }
    return [
      BoxShadow(
        color: catalogCardRest,
        blurRadius: 2,
        offset: const Offset(0, 1),
      ),
    ];
  }

  List<BoxShadow> dialog({double opacity = 1}) {
    return [
      BoxShadow(
        color: dialogPrimary.withValues(alpha: dialogPrimary.a * opacity),
        blurRadius: 16,
        offset: const Offset(0, 8),
      ),
      BoxShadow(
        color: dialogSecondary.withValues(alpha: dialogSecondary.a * opacity),
        blurRadius: 4,
        offset: const Offset(0, 2),
      ),
    ];
  }

  List<BoxShadow> toast() {
    return [
      BoxShadow(
        color: toastPrimary,
        blurRadius: 16,
        offset: const Offset(0, 8),
      ),
      BoxShadow(
        color: toastSecondary,
        blurRadius: 4,
        offset: const Offset(0, 2),
      ),
    ];
  }

  List<BoxShadow> contextMenuPanel() {
    return [
      BoxShadow(
        color: contextMenu,
        blurRadius: 12,
        offset: const Offset(0, 4),
      ),
    ];
  }
}
