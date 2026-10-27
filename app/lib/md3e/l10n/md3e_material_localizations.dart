import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:hentai_library/core/l10n/app_localizations.dart';
import 'package:material_ui/material_ui.dart' as mui;

/// MD3E Lab / M3E 组件用本地化委托（应用 ARB + **material_ui** Material/Cupertino/Widgets）。
///
/// [M3ECalendarDatePicker] 等调用的是 `package:material_ui` 的
/// [mui.MaterialLocalizations.of]，须保留 [mui.GlobalMaterialLocalizations.delegates]。
///
/// Lab 里仍有 `package:flutter/material.dart` 的 [showDialog] / [Dialog]（如管理页新建实体），
/// 其校验的是 Flutter 自带的 [MaterialLocalizations]，故额外挂上
/// [GlobalMaterialLocalizations.delegate]（与 material_ui 的 MaterialLocalizations 类型不同，可并存）。
List<LocalizationsDelegate<dynamic>> get md3eMaterialLocalizationsDelegates =>
    <LocalizationsDelegate<dynamic>>[
      AppLocalizations.delegate,
      ...mui.GlobalMaterialLocalizations.delegates,
      GlobalMaterialLocalizations.delegate,
    ];
