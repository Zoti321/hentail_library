import 'package:flutter/widgets.dart';
import 'package:hentai_library/core/l10n/app_localizations.dart';
import 'package:material_ui/material_ui.dart' as mui;

/// MD3E Lab / M3E 组件用本地化委托（应用 ARB + **material_ui** Material/Cupertino/Widgets）。
///
/// [M3ECalendarDatePicker] 等调用的是 `package:material_ui` 的
/// [mui.MaterialLocalizations.of]，勿使用 Flutter 自带的
/// `GlobalMaterialLocalizations`。
List<LocalizationsDelegate<dynamic>> get md3eMaterialLocalizationsDelegates =>
    <LocalizationsDelegate<dynamic>>[
      AppLocalizations.delegate,
      ...mui.GlobalMaterialLocalizations.delegates,
    ];
