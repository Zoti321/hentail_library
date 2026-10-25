import 'package:flutter/material.dart';
import 'package:hentai_library/core/l10n/app_localizations.dart';
import 'package:hentai_library/md3e/theme/md3e_theme.dart';
import 'package:material_3_expressive/foundations/foundations.dart';

import 'md3e_widgetbook_l10n_scope.dart';

/// Wraps each Widgetbook use-case preview in [M3EMaterialApp] + lab theme.
Widget md3eWidgetbookAppBuilder(BuildContext context, Widget child) {
  final M3EThemeData m3e = buildMd3eThemeData();

  return M3EMaterialApp(
    data: m3e,
    fontFamily: kMd3eAppFontFamily,
    debugShowCheckedModeBanner: false,
    // material_ui MaterialLocalizations only fully covers `en`.
    locale: const Locale('en'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    appBuilder: (BuildContext context, Widget? themedChild) {
      return DefaultTextStyle.merge(
        style: const TextStyle(fontFamily: kMd3eAppFontFamily),
        child: themedChild ?? const SizedBox.shrink(),
      );
    },
    home: Md3eWidgetbookAppLocalizationsScope(child: child),
  );
}
