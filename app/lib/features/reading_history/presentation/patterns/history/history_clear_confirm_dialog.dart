import 'package:flutter/material.dart';
import 'package:hentai_library/core/l10n/app_localizations.dart';
import 'package:hentai_library/core/l10n/app_localizations_x.dart';
import 'package:hentai_library/shared/ui/patterns/dialog/lab_dialog_presenter.dart';
import 'package:hentai_library/design-system/design_system.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

/// Lab：清空全部阅读历史的二次确认（文案与生产 [ClearReadingHistoryConfirmDialog] 一致）。
Future<bool> showClearReadingHistoryConfirmDialog({
  required BuildContext context,
}) async {
  final bool? confirmed = await LabDialogPresenter.showBasic<bool>(
    context,
    dialog: const _ClearReadingHistoryConfirmPanel(),
  );
  return confirmed ?? false;
}

class _ClearReadingHistoryConfirmPanel extends StatelessWidget {
  const _ClearReadingHistoryConfirmPanel();

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final M3EThemeData theme = M3ETheme.of(context);
    final TextStyle actionLabelStyle = labButtonLabelStyle(
      theme,
      M3EButtonSize.sm,
    );

    return M3EDialog(
      title: l10n.confirmClearHistoryTitle,
      content: Text(
        l10n.confirmClearHistoryContent,
        style: theme.typeScale.bodyMedium.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
      bottomDivider: true,
      actions: <Widget>[
        M3EButton(
          onPressed: () => Navigator.of(context).pop(false),
          style: M3EButtonStyle.text,
          decoration: M3EButtonDecoration(textStyle: actionLabelStyle),
          label: Text(l10n.commonCancel),
        ),
        M3EButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: M3EButtonStyle.filled,
          decoration: M3EButtonDecoration(textStyle: actionLabelStyle),
          label: Text(l10n.commonClear),
        ),
      ],
    );
  }
}
