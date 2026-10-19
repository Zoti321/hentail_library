import 'package:flutter/material.dart';
import 'package:hentai_library/shared/ui/theme/color/app_shadow_palette.dart';
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

  @override
  final Color catalogCardRest;
  @override
  final Color catalogCardHover;
  @override
  final Color dialogPrimary;
  @override
  final Color dialogSecondary;
  @override
  final Color toastPrimary;
  @override
  final Color toastSecondary;
  @override
  final Color contextMenu;

  factory AppShadowTokens.fromPalette(AppShadowPalette palette) {
    return AppShadowTokens(
      catalogCardRest: palette.catalogCardRest,
      catalogCardHover: palette.catalogCardHover,
      dialogPrimary: palette.catalogCardHover,
      dialogSecondary: palette.catalogCardRest,
      toastPrimary: palette.catalogCardHover,
      toastSecondary: palette.catalogCardRest,
      contextMenu: palette.contextMenu,
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

  /// Four-layer stack for dialogs, toasts, and adaptive form surfaces.
  List<BoxShadow> elevatedSurface({required bool isDark, double opacity = 1}) {
    final Color ambient = isDark
        ? Colors.black.withAlpha(52)
        : Colors.black.withAlpha(14);
    final Color contact = isDark
        ? Colors.black.withAlpha(72)
        : Colors.black.withAlpha(22);
    Color scaled(Color color) =>
        color.withValues(alpha: color.a * opacity.clamp(0.0, 1.0));

    return <BoxShadow>[
      BoxShadow(
        color: scaled(ambient),
        blurRadius: 32,
        spreadRadius: -4,
        offset: const Offset(0, 14),
      ),
      BoxShadow(
        color: scaled(dialogPrimary),
        blurRadius: 24,
        offset: const Offset(0, 8),
      ),
      BoxShadow(
        color: scaled(dialogSecondary),
        blurRadius: 8,
        offset: const Offset(0, 2),
      ),
      BoxShadow(
        color: scaled(contact),
        blurRadius: 4,
        offset: const Offset(0, 1),
      ),
    ];
  }

  List<BoxShadow> dialog({double opacity = 1, required bool isDark}) =>
      elevatedSurface(isDark: isDark, opacity: opacity);

  List<BoxShadow> toast({required bool isDark}) =>
      elevatedSurface(isDark: isDark);

  /// Dropdown / popup panel (menus, multi-select).
  List<BoxShadow> raisedPanel({
    double blurRadius = 8,
    Offset offset = const Offset(0, 4),
  }) {
    return <BoxShadow>[
      BoxShadow(
        color: catalogCardHover,
        blurRadius: blurRadius,
        offset: offset,
      ),
    ];
  }

  List<BoxShadow> subtleRest() {
    return <BoxShadow>[
      BoxShadow(
        color: catalogCardRest,
        blurRadius: 2,
        offset: const Offset(0, 1),
      ),
    ];
  }

  /// Bottom fade on pinned page headers ([PagePinnedHeaderDelegate]).
  List<Color> pinnedHeaderShadowGradient() {
    return <Color>[
      catalogCardRest.withValues(alpha: 0),
      catalogCardRest.withValues(alpha: 0.025),
      catalogCardRest.withValues(alpha: 0.05),
    ];
  }

  List<BoxShadow> contextMenuPanel() {
    return [
      BoxShadow(color: contextMenu, blurRadius: 12, offset: const Offset(0, 4)),
    ];
  }
}
