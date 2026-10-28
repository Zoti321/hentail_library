import 'package:flutter/widgets.dart';
import 'package:hentai_library/md3e/layout/md3e_breakpoints.dart';
import 'package:hentai_library/md3e/patterns/dialog/md3e_lab_dialog_route.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

/// Lab 对话框统一入口（M3EDialog；断点与 [Md3eBreakpoints.expanded] 对齐）。
abstract final class Md3eLabDialogPresenter {
  static bool usesFullScreenPresentation(BuildContext context) {
    return md3eWindowSizeClassOf(context).usesMetadataEditFullScreenRoute;
  }

  static Future<T?> showBasic<T>(
    BuildContext context, {
    required Widget dialog,
    bool barrierDismissible = true,
    M3EDialogPosition position = M3EDialogPosition.center,
  }) {
    return md3ePushLabDialogRoute<T>(
      context,
      variant: M3EDialogVariant.basic,
      barrierDismissible: barrierDismissible,
      builder: (BuildContext routeContext) {
        return M3EScrimSystemUi.wrap(
          M3EDialogInset(
            padding: M3ETheme.of(routeContext).dialogTheme.screenMargin,
            alignment: position.alignment,
            child: dialog,
          ),
        );
      },
    );
  }

  static Future<T?> showFullScreen<T>(
    BuildContext context, {
    required String title,
    required Widget body,
    String? confirmLabel,
    VoidCallback? onConfirm,
    List<Widget> bottomActions = const <Widget>[],
  }) {
    return md3ePushLabDialogRoute<T>(
      context,
      variant: M3EDialogVariant.fullScreen,
      barrierDismissible: false,
      builder: (_) {
        return M3EFullScreenDialog(
          title: title,
          body: body,
          confirmLabel: confirmLabel,
          onConfirm: onConfirm,
          bottomActions: bottomActions,
        );
      },
    );
  }
}
