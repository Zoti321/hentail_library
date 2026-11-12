import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:hentai_library/core/l10n/app_localizations.dart';
import 'package:material_ui/material_ui.dart'
    show DefaultMaterialLocalizations, MaterialLocalizations;

export 'package:material_ui/material_ui.dart' show MaterialLocalizations;

/// ## MD3E 自研 UI 与 material_ui
///
/// 新写的 MD3E 输入 / 日历 / 与 M3E 包同屏的自研控件，**文案与 Material 本地化统一走 material_ui**
/// [MaterialLocalizations]（经 [materialLocalizationsOf]），不要再用 Flutter
/// `package:flutter/material.dart` 里的 [MaterialLocalizations]。
///
/// **作用域**
/// - 应用 ARB（`context.l10n`）：由 [MaterialApp] 或 [materialLocalizationsDelegates] 提供。
/// - 日历整棵子树：根节点包 [materialUiLocalizationsScope]（`en` + material_ui delegate）。
/// - Overlay / Lab 对话框：单层 [materialLocalizationsDelegates]（ARB + material_ui + Flutter Material，供 legacy 控件）。
///
/// material_ui [DefaultMaterialLocalizations] 仅完整支持 `en`；日历子树固定 `en` locale。
List<LocalizationsDelegate<dynamic>> get materialLocalizationsDelegates =>
    <LocalizationsDelegate<dynamic>>[
      AppLocalizations.delegate,
      DefaultMaterialLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
    ];

/// material_ui [MaterialLocalizations.of]；调用方须在 [MaterialUiLocalizationsScope] 或
/// 已注册 [DefaultMaterialLocalizations.delegate] 且 locale 为 `en` 的子树内。
MaterialLocalizations materialLocalizationsOf(BuildContext context) {
  return MaterialLocalizations.of(context);
}

/// 日历 / M3E 日期控件子树（整表包一层，勿包整弹窗）。
class MaterialUiLocalizationsScope extends StatelessWidget {
  const MaterialUiLocalizationsScope({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Localizations(
      locale: const Locale('en'),
      delegates: const <LocalizationsDelegate<dynamic>>[
        DefaultMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      child: child,
    );
  }
}
