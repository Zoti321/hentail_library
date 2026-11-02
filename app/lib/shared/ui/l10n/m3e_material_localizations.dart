import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:hentai_library/core/l10n/app_localizations.dart';

/// M3E 组件用本地化委托（应用 ARB + Flutter Material/Widgets）。
List<LocalizationsDelegate<dynamic>> get md3eMaterialLocalizationsDelegates =>
    <LocalizationsDelegate<dynamic>>[
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
    ];
