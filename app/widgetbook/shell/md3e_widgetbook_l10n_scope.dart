import 'package:flutter/widgets.dart';
import 'package:hentai_library/core/l10n/app_localizations.dart';

import 'md3e_widgetbook_localizations.dart';

/// Zh [AppLocalizations] for lab previews without forcing `zh` on material_ui.
///
/// Sits under [M3EMaterialApp] (`locale: en` for Material/Cupertino delegates).
/// Merges with the parent [Localizations] so [WidgetsLocalizations] stays valid;
/// only [AppLocalizations] is overridden to `zh`.
class Md3eWidgetbookAppLocalizationsScope extends StatelessWidget {
  const Md3eWidgetbookAppLocalizationsScope({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Localizations.override(
      context: context,
      locale: const Locale('zh'),
      delegates: md3eWidgetbookLocalizationsDelegates,
      child: child,
    );
  }
}
