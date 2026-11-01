import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:hentai_library/core/l10n/app_localizations.dart';
import 'package:material_ui/material_ui.dart' as mui;

/// M3E 组件用本地化委托（应用 ARB + **material_ui** Material/Cupertino/Widgets）。
List<LocalizationsDelegate<dynamic>> get md3eMaterialLocalizationsDelegates =>
    <LocalizationsDelegate<dynamic>>[
      AppLocalizations.delegate,
      ...mui.GlobalMaterialLocalizations.delegates,
      GlobalMaterialLocalizations.delegate,
    ];
