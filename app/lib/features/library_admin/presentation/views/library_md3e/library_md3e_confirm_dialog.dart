import 'package:flutter/material.dart';
import 'package:hentai_library/core/l10n/app_localizations.dart';
import 'package:hentai_library/core/l10n/app_localizations_x.dart';
import 'package:hentai_library/md3e/patterns/dialog/md3e_lab_dialog_presenter.dart';
import 'package:hentai_library/md3e/theme/md3e_theme.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

/// Library 相关的 MD3E 确认对话框（取消 / 确认两个按钮）。
///
/// 返回 `true` 表示用户确认，其它情况（取消、点击遮罩）返回 `false`。
Future<bool> showLibraryMd3eConfirmDialog(
  BuildContext context, {
  required String title,
  required Widget content,
  required String confirmLabel,
  bool destructive = false,
}) async {
  final M3EThemeData m3e = md3eWithAppFontFamily(M3ETheme.of(context));
  final bool? confirmed = await Md3eLabDialogPresenter.showBasic<bool>(
    context,
    dialog: M3ETheme(
      data: m3e,
      child: _LibraryMd3eConfirmDialog(
        title: title,
        content: content,
        confirmLabel: confirmLabel,
        destructive: destructive,
      ),
    ),
  );
  return confirmed ?? false;
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

class _LibraryMd3eConfirmDialog extends StatelessWidget {
  const _LibraryMd3eConfirmDialog({
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
    final M3EThemeData theme = M3ETheme.of(context);
    final M3EColorScheme scheme = theme.colorScheme;

    return M3EDialog(
      title: title,
      content: content,
      bottomDivider: true,
      actions: <Widget>[
        M3EButton(
          onPressed: () => Navigator.of(context).pop(false),
          style: M3EButtonStyle.text,
          label: Text(l10n.commonCancel),
        ),
        M3EButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: M3EButtonStyle.filled,
          decoration: destructive
              ? M3EButtonDecoration.styleFrom(
                  backgroundColor: scheme.error,
                  foregroundColor: scheme.onError,
                )
              : null,
          label: Text(confirmLabel),
        ),
      ],
    );
  }
}
