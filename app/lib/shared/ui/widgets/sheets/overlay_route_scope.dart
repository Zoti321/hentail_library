import 'package:flutter/material.dart';
import 'package:hentai_library/shared/ui/l10n/m3e_material_localizations.dart';
import 'package:hentai_library/shared/ui/theme/app_m3e_theme.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

/// 路由 / overlay 所需的主题与本地化快照。
///
/// 必须在**发起导航或打开 overlay 的同步调用栈中**通过 [OverlayRouteScopeSnapshot.capture]
/// 取得；路由 builder 可能在锚点 context 已 deactivate 之后才执行（例如目录刷新导致列表项被移除），
/// 此时再查找祖先 InheritedWidget 会触发 "Looking up a deactivated widget's ancestor" 断言。
final class OverlayRouteScopeSnapshot {
  const OverlayRouteScopeSnapshot._({
    required this.locale,
    required this.m3e,
    required this.materialTheme,
  });

  factory OverlayRouteScopeSnapshot.capture(BuildContext anchorContext) {
    final M3EThemeData m3e = M3ETheme.of(anchorContext);
    return OverlayRouteScopeSnapshot._(
      locale: Localizations.localeOf(anchorContext),
      m3e: m3e,
      materialTheme: buildMaterialTheme(m3e.colorScheme.brightness, m3e: m3e),
    );
  }

  OverlayRouteScopeSnapshot withM3e(M3EThemeData m3e) {
    return OverlayRouteScopeSnapshot._(
      locale: locale,
      m3e: m3e,
      materialTheme: buildMaterialTheme(m3e.colorScheme.brightness, m3e: m3e),
    );
  }

  final Locale locale;
  final M3EThemeData m3e;
  final ThemeData materialTheme;
}

/// 为 root overlay / [M3ESideSheet] 等路由重挂 [M3ETheme]、[Theme]、本地化。
///
/// Widgetbook shell 的 overlay 常在 [M3EMaterialApp] 之上，子树内 `context.l10n` 会空；
/// [Material] 供 [InkWell] 等 legacy 控件使用；[DefaultTextStyle] 对齐 Lab 字体（含 M3E 全屏标题）。
///
/// [scope] 应由调用方在构建路由前通过 [OverlayRouteScopeSnapshot.capture] 获取。
Widget overlayRouteScope({
  required OverlayRouteScopeSnapshot scope,
  required Widget child,
}) {
  return Localizations(
    locale: scope.locale,
    delegates: materialLocalizationsDelegates,
    child: M3ETheme(
      data: scope.m3e,
      child: Theme(
        data: scope.materialTheme,
        child: DefaultTextStyle.merge(
          style: const TextStyle(fontFamily: kAppFontFamily),
          child: Material(type: MaterialType.transparency, child: child),
        ),
      ),
    ),
  );
}
