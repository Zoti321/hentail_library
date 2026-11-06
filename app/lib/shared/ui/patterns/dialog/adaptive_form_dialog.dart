import 'package:flutter/material.dart';
import 'package:hentai_library/shared/ui/layout/breakpoints.dart';
import 'package:hentai_library/shared/ui/layout/metadata_edit_form_metrics.dart';
import 'package:hentai_library/shared/ui/patterns/metadata_edit/metadata_edit_form_scroll.dart';
import 'package:hentai_library/shared/ui/widgets/sheets/overlay_route_scope.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

/// 表单类弹窗统一入口：基于 [M3EDialog.showAdaptive]。
///
/// 宽度 < [Breakpoints.expanded]（840）时为全屏，否则为 M3EDialog 基础弹窗；
/// 断点由应用主题 `dialogTheme.compactBreakpoint` 提供（见 `buildAppM3eThemeData`）。
/// [form] 只传表单主体，标题与按钮由弹窗提供；基础变体下限制 [basicMaxWidth]。
Future<T?> showAdaptiveFormDialog<T>(
  BuildContext context, {
  required String title,
  required Widget form,
  required String confirmLabel,
  required String dismissLabel,
  required VoidCallback? onConfirm,
  required double basicMaxWidth,
}) {
  final bool fullScreen = windowSizeClassOf(context)
      .usesMetadataEditFullScreenRoute;
  final M3EThemeData theme = M3ETheme.of(context);
  final double contentWidth = fullScreen
      ? basicMaxWidth
      : MetadataEditFormMetrics.dialogContentMaxWidth(context);
  final double contentHeight = MetadataEditFormMetrics.dialogContentMaxHeight(
    context,
  );
  // 表单主体由 ComicMetadataEditForm 自行分区滚动，避免对话框双层滚动与滚动条。
  final Widget material = Material(
    type: MaterialType.transparency,
    child: ScrollConfiguration(
      behavior: MetadataEditScrollBehavior(),
      child: SizedBox(
        height: contentHeight,
        width: double.infinity,
        child: form,
      ),
    ),
  );
  final Widget content = fullScreen
      ? material
      : ConstrainedBox(
          constraints: BoxConstraints(maxWidth: contentWidth),
          child: material,
        );
  final M3EThemeData themed = theme.copyWith(
    dialogTheme: theme.dialogTheme.copyWith(
      maxWidth: MetadataEditFormMetrics.dialogShellMaxWidth(context),
    ),
  );
  final M3EAdaptiveDialog adaptiveDialog = M3EAdaptiveDialog(
    title: title,
    content: content,
    confirmLabel: confirmLabel,
    onConfirm: onConfirm,
    dismissLabel: dismissLabel,
  );

  if (fullScreen) {
    return M3EDialog.showAdaptive<T>(
      context,
      title: title,
      content: content,
      confirmLabel: confirmLabel,
      dismissLabel: dismissLabel,
      onConfirm: onConfirm,
    );
  }

  final OverlayRouteScopeSnapshot scope = OverlayRouteScopeSnapshot.capture(
    context,
  );

  return M3EDialog.show<T>(
    context,
    dialog: overlayRouteScope(
      scope: scope.withM3e(themed),
      child: adaptiveDialog,
    ),
  );
}
