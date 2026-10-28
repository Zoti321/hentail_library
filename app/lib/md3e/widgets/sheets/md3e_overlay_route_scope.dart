import 'package:flutter/material.dart';
import 'package:hentai_library/md3e/l10n/md3e_material_localizations.dart';
import 'package:hentai_library/md3e/theme/md3e_theme.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

/// 为 root overlay / [M3ESideSheet] 等路由重挂 [M3ETheme]、[Theme]、[AppLocalizations]。
///
/// Widgetbook shell 的 overlay 常在 [M3EMaterialApp] 之上，子树内 `context.l10n` 会空；
/// [Material] 供 [InkWell] 等 legacy 控件使用；[DefaultTextStyle] 对齐 Lab 字体（含 M3E 全屏标题）。
Widget md3eOverlayRouteScope({
  required BuildContext anchorContext,
  required Widget child,
}) {
  final M3EThemeData m3e = M3ETheme.of(anchorContext);
  final ThemeData materialTheme = buildMd3eMaterialTheme(
    m3e.colorScheme.brightness,
    m3e: m3e,
  );

  return Localizations(
    locale: Localizations.localeOf(anchorContext),
    delegates: md3eMaterialLocalizationsDelegates,
    child: M3ETheme(
      data: m3e,
      child: Theme(
        data: materialTheme,
        child: DefaultTextStyle.merge(
          style: const TextStyle(fontFamily: kMd3eAppFontFamily),
          child: Material(
            type: MaterialType.transparency,
            child: child,
          ),
        ),
      ),
    ),
  );
}
