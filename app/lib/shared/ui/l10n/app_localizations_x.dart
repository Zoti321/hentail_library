import 'package:flutter/widgets.dart';
import 'package:hentai_library/l10n/app_localizations.dart';

extension AppLocalizationsContextX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}
