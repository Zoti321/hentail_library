import 'package:flutter/material.dart';
import 'package:hentai_library/shared/ui/layout/breakpoints.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

/// 表单类弹窗统一入口：基于 [M3EDialog.showAdaptive]。
///
/// 宽度 < [Md3eBreakpoints.expanded]（840）时为全屏，否则为 M3EDialog 基础弹窗；
/// 断点由应用主题 `dialogTheme.compactBreakpoint` 提供（见 `buildAppM3eThemeData`）。
/// [form] 只传表单主体，标题与按钮由弹窗提供；基础变体下限制 [basicMaxWidth]。
Future<T?> showMd3eAdaptiveFormDialog<T>(
  BuildContext context, {
  required String title,
  required Widget form,
  required String confirmLabel,
  required String dismissLabel,
  required VoidCallback? onConfirm,
  required double basicMaxWidth,
}) {
  final bool fullScreen = md3eWindowSizeClassOf(context)
      .usesMetadataEditFullScreenRoute;
  // 表单内含 InkWell（设置式开关行等），需要 Material 祖先；透明 Material 不绘制任何颜色。
  final Widget material = Material(
    type: MaterialType.transparency,
    child: form,
  );
  return M3EDialog.showAdaptive<T>(
    context,
    title: title,
    content: fullScreen
        ? material
        : ConstrainedBox(
            constraints: BoxConstraints(maxWidth: basicMaxWidth),
            child: material,
          ),
    confirmLabel: confirmLabel,
    dismissLabel: dismissLabel,
    onConfirm: onConfirm,
  );
}
