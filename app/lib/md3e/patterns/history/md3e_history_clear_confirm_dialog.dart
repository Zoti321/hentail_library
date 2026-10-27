import 'package:flutter/material.dart';
import 'package:hentai_library/md3e/l10n/md3e_l10n.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

/// Lab：清空全部阅读历史的二次确认（文案与生产 [ClearReadingHistoryConfirmDialog] 一致）。
Future<bool> showMd3eClearReadingHistoryConfirmDialog({
  required BuildContext context,
}) async {
  final bool? confirmed = await showDialog<bool>(
    context: context,
    useRootNavigator: false,
    builder: (BuildContext dialogContext) {
      return const _Md3eClearReadingHistoryConfirmDialog();
    },
  );
  return confirmed ?? false;
}

class _Md3eClearReadingHistoryConfirmDialog extends StatelessWidget {
  const _Md3eClearReadingHistoryConfirmDialog();

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final M3EThemeData theme = M3ETheme.of(context);
    final M3ESpacing spacing = theme.spacing;

    return Dialog(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          spacing.lg,
          spacing.lg,
          spacing.lg,
          spacing.md,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(
              l10n.confirmClearHistoryTitle,
              style: theme.typeScale.titleLarge.copyWith(
                color: theme.colorScheme.onSurface,
              ),
            ),
            SizedBox(height: spacing.md),
            Text(
              l10n.confirmClearHistoryContent,
              style: theme.typeScale.bodyMedium.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            SizedBox(height: spacing.lg),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: <Widget>[
                M3EButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  style: M3EButtonStyle.text,
                  label: Text(l10n.commonCancel),
                ),
                SizedBox(width: spacing.sm),
                M3EButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  style: M3EButtonStyle.filled,
                  label: Text(l10n.commonClear),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
