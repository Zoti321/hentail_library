import 'package:flutter/material.dart';
import 'package:hentai_library/core/l10n/app_localizations.dart';

/// Applies zh (or [locale]) AppLocalizations delegates to a [MaterialApp].
///
/// Prefer [pumpLocalizedApp] from `pump_localized_app.dart` for new widget tests.
/// Spread these onto an existing MaterialApp only when a custom shell is required.
({
  List<LocalizationsDelegate<dynamic>> delegates,
  List<Locale> locales,
  Locale locale,
})
localizedTestAppConfig({Locale locale = const Locale('zh')}) {
  return (
    delegates: AppLocalizations.localizationsDelegates,
    locales: AppLocalizations.supportedLocales,
    locale: locale,
  );
}
