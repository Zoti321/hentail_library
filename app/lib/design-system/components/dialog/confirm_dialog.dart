import 'package:flutter/material.dart';

import '../../l10n/design_system_localizations.dart';
import 'lab_dialog_presenter.dart';
import '../scaffold/dialog_action_bar.dart';
import '../../theme/app_m3e_theme.dart';

import 'package:material_3_expressive/material_3_expressive.dart';

/// 通用 MD3E 确认对话框（取消 / 确认两个按钮）。
///
/// 返回 `true` 表示用户确认，其它情况（取消、点击遮罩）返回 `false`。
Future<bool> showConfirmDialog(
  BuildContext context, {
  required String title,
  required Widget content,
  required String confirmLabel,
  bool destructive = false,
}) async {
  final M3EThemeData m3e = withAppFontFamily(M3ETheme.of(context));
  final bool? confirmed = await LabDialogPresenter.showBasic<bool>(
    context,
    dialog: M3ETheme(
      data: m3e,
      child: _ConfirmDialog(
        title: title,
        content: content,
        confirmLabel: confirmLabel,
        destructive: destructive,
      ),
    ),
  );
  return confirmed ?? false;
}

class _ConfirmDialog extends StatelessWidget {
  const _ConfirmDialog({
    required this.title,
    required this.content,
    required this.confirmLabel,
    required this.destructive,
  });

  final String title;
  final Widget content;
  final String confirmLabel;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final DesignSystemLocalizations l10n = DesignSystemLocalizations.of(
      context,
    );

    return M3EDialog(
      title: title,
      content: content,
      bottomDivider: true,
      actions: <Widget>[
        DialogActionBar(
          onCancel: () => Navigator.of(context).pop(false),
          onConfirm: () => Navigator.of(context).pop(true),
          cancelLabel: l10n.cancelLabel,
          confirmLabel: confirmLabel,
          destructive: destructive,
        ),
      ],
    );
  }
}
