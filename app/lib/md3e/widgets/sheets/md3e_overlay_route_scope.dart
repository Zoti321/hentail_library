import 'package:flutter/material.dart';
import 'package:hentai_library/md3e/l10n/md3e_material_localizations.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

/// 为 root overlay / [M3ESideSheet] 等路由重挂 [M3ETheme] 与 [AppLocalizations]。
///
/// Widgetbook shell 的 overlay 常在 [M3EMaterialApp] 之上，子树内 `context.l10n` 会空。
Widget md3eOverlayRouteScope({
  required BuildContext anchorContext,
  required Widget child,
}) {
  return Localizations(
    locale: Localizations.localeOf(anchorContext),
    delegates: md3eMaterialLocalizationsDelegates,
    child: M3ETheme(
      data: M3ETheme.of(anchorContext),
      child: child,
    ),
  );
}
