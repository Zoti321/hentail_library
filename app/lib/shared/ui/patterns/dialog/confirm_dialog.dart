import 'package:flutter/material.dart';
import 'package:hentai_library/core/l10n/app_localizations.dart';
import 'package:hentai_library/core/l10n/app_localizations_x.dart';
import 'package:hentai_library/shared/ui/patterns/dialog/lab_dialog_presenter.dart';
import 'package:hentai_library/design-system/design_system.dart';
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
    final AppLocalizations l10n = context.l10n;

    return M3EDialog(
      title: title,
      content: content,
      bottomDivider: true,
      actions: <Widget>[
        DialogActionBar(
          onCancel: () => Navigator.of(context).pop(false),
          onConfirm: () => Navigator.of(context).pop(true),
          cancelLabel: l10n.commonCancel,
          confirmLabel: confirmLabel,
          destructive: destructive,
        ),
      ],
    );
  }
}
