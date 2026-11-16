import 'package:hentai_library/l10n/app_localizations.dart';
import 'package:flutter/widgets.dart';
import 'package:hentai_library/design-system/design_system.dart';

/// Widgetbook 与 [materialLocalizationsDelegates] 一致。
List<LocalizationsDelegate<dynamic>> get md3eWidgetbookLocalizationsDelegates =>
    <LocalizationsDelegate<dynamic>>[
      AppLocalizations.delegate,
      ...materialLocalizationsDelegates,
    ];
