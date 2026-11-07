import 'package:flutter/material.dart';
import 'package:hentai_library/shared/ui/widgets/sheets/overlay_route_scope.dart';
import 'package:material_3_expressive/components/dialogs/components/m3e_dialog_dismiss_scope.dart';
import 'package:material_3_expressive/components/dialogs/components/m3e_dialog_transition.dart';
import 'package:material_3_expressive/components/dialogs/res/m3e_dialog_strings.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

/// Lab 对话框路由：与 M3E 包动画/scrim 一致，但 [rootNavigator: false]（Widgetbook 预览内）。
Future<T?> pushLabDialogRoute<T>(
  BuildContext anchorContext, {
  required M3EDialogVariant variant,
  required bool barrierDismissible,
  required WidgetBuilder builder,
  M3EDialogController? controller,
  Future<bool> Function()? onDismissRequest,
  bool autofocusFirst = true,
}) {
  final M3EThemeData theme = M3ETheme.of(anchorContext);
  final M3EDialogTheme dialogTheme = theme.dialogTheme;

  Future<bool?> discardPrompt(
    BuildContext context,
    M3EDialogDiscardLabels labels,
  ) {
    return M3EDialog.showDiscardConfirmation(context, labels: labels);
  }

  final OverlayRouteScopeSnapshot overlayScope =
      OverlayRouteScopeSnapshot.capture(anchorContext);
  return Navigator.of(anchorContext, rootNavigator: false).push<T>(
    RawDialogRoute<T>(
      barrierDismissible: barrierDismissible,
      barrierLabel: variant == M3EDialogVariant.basic
          ? M3EDialogStrings.dismiss
          : M3EDialogStrings.fullScreen,
      barrierColor: dialogTheme.scrimColor(theme.colorScheme),
      transitionDuration: M3EDialogTransition.durationFor(dialogTheme, variant),
      traversalEdgeBehavior: TraversalEdgeBehavior.closedLoop,
      pageBuilder: (BuildContext routeContext, _, _) {
        return M3EComponentTheme(
          builder: (BuildContext themedContext) {
            return M3EDialogDismissScope(
              controller: controller,
              onDismissRequest: onDismissRequest,
              autofocusFirst: autofocusFirst,
              variant: variant,
              discardPrompt: discardPrompt,
              child: overlayRouteScope(
                scope: overlayScope,
                child: builder(themedContext),
              ),
            );
          },
        );
      },
      transitionBuilder:
          (BuildContext context, Animation<double> animation, _, Widget child) {
            return M3EDialogTransition(
              animation: animation,
              variant: variant,
              dialogTheme: dialogTheme,
              child: child,
            );
          },
    ),
  );
}
