import 'package:flutter/material.dart';
import 'package:hentai_library/core/l10n/app_localizations.dart';
import 'package:hentai_library/core/l10n/app_localizations_x.dart';
import 'package:hentai_library/shared/ui/patterns/dialog/md3e_confirm_dialog.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

/// Library 相关的 MD3E 确认对话框（委托共享 [showMd3eConfirmDialog]）。
Future<bool> showLibraryMd3eConfirmDialog(
  BuildContext context, {
  required String title,
  required Widget content,
  required String confirmLabel,
  bool destructive = false,
}) {
  return showMd3eConfirmDialog(
    context,
    title: title,
    content: content,
    confirmLabel: confirmLabel,
    destructive: destructive,
  );
}

/// 从已保存路径列表中移除一条路径前的确认（不删除磁盘文件）。
Future<bool> showLibraryMd3eRemovePathConfirm(
  BuildContext context, {
  required String path,
}) {
  final AppLocalizations l10n = context.l10n;
  final M3EThemeData theme = M3ETheme.of(context);
  return showLibraryMd3eConfirmDialog(
    context,
    title: l10n.confirmRemovePathTitle,
    content: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(
          l10n.confirmRemovePathContent,
          style: theme.typeScale.bodyMedium.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          path,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
          style: theme.typeScale.bodyMedium.copyWith(
            fontWeight: FontWeight.w500,
            color: theme.colorScheme.onSurface,
          ),
        ),
      ],
    ),
    confirmLabel: l10n.commonRemove,
    destructive: true,
  );
}
