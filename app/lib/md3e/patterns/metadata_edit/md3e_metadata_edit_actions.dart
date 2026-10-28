import 'package:flutter/material.dart';
import 'package:hentai_library/md3e/l10n/md3e_l10n.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

/// 元数据 / Library 编辑 M3EDialog 底部 actions（Cancel + Save）。
List<Widget> md3eMetadataEditDialogActions(
  BuildContext context, {
  required VoidCallback? onCancel,
  required VoidCallback? onSave,
  required bool saving,
  required bool saveEnabled,
}) {
  final AppLocalizations l10n = context.l10n;
  final M3EThemeData theme = M3ETheme.of(context);

  return <Widget>[
    M3EButton(
      onPressed: saving ? null : onCancel,
      style: M3EButtonStyle.text,
      label: Text(l10n.commonCancel),
    ),
    M3EButton(
      onPressed: saving || !saveEnabled ? null : onSave,
      style: M3EButtonStyle.filled,
      label: saving
          ? SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: theme.colorScheme.onPrimary,
              ),
            )
          : Text(l10n.commonSave),
    ),
  ];
}
