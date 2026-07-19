import 'package:flutter/material.dart';
import 'package:hentai_library/core/l10n/app_localizations.dart';

/// Applies zh (or [locale]) AppLocalizations delegates to a [MaterialApp].
///
/// Prefer spreading these onto an existing MaterialApp rather than nesting
/// another MaterialApp.
({List<LocalizationsDelegate<dynamic>> delegates, List<Locale> locales, Locale locale})
localizedTestAppConfig({Locale locale = const Locale('zh')}) {
  return (
    delegates: AppLocalizations.localizationsDelegates,
    locales: AppLocalizations.supportedLocales,
    locale: locale,
  );
}
