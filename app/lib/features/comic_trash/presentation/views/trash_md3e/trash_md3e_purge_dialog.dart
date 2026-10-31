import 'package:flutter/material.dart';
import 'package:hentai_library/core/l10n/app_localizations.dart';
import 'package:hentai_library/core/l10n/app_localizations_x.dart';
import 'package:hentai_library/md3e/patterns/dialog/md3e_lab_dialog_presenter.dart';
import 'package:hentai_library/md3e/theme/md3e_lab_text.dart';
import 'package:hentai_library/shared/domain/comic_trash/comic_purge_policy.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

/// 永久删除（Comic purge）前的危险确认框：MD3E 壳 + 勾选闸门（ADR-0023）。
///
/// 单本传入 [title]；批量或「全部永久删除」传 null。混选时分别展示 Local / Remote 数量。
Future<bool> showTrashMd3ePurgeConfirmDialog({
  required BuildContext context,
  String? title,
  required PurgeTargetCounts counts,
}) async {
  final bool? confirmed = await Md3eLabDialogPresenter.showBasic<bool>(
    context,
    dialog: Md3eTrashPurgeConfirmDialog(title: title, counts: counts),
  );
  return confirmed ?? false;
}

class Md3eTrashPurgeConfirmDialog extends StatefulWidget {
  const Md3eTrashPurgeConfirmDialog({
    super.key,
    this.title,
    required this.counts,
  });

  final String? title;
  final PurgeTargetCounts counts;

  @override
  State<Md3eTrashPurgeConfirmDialog> createState() =>
      _Md3eTrashPurgeConfirmDialogState();
}

class _Md3eTrashPurgeConfirmDialogState
    extends State<Md3eTrashPurgeConfirmDialog> {
  bool _acknowledged = false;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final M3EThemeData theme = M3ETheme.of(context);
    final M3EColorScheme scheme = theme.colorScheme;
    final TextStyle actionLabelStyle = md3eLabButtonLabelStyle(
      theme,
      M3EButtonSize.sm,
    );
    final bool needsAcknowledgement = purgeRequiresAcknowledgement(
      widget.counts,
    );
    final bool canConfirm = !needsAcknowledgement || _acknowledged;

    return M3EDialog(
      title: l10n.comicPurgeTitle,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            _message(l10n),
            style: theme.typeScale.bodyMedium.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          if (needsAcknowledgement) ...<Widget>[
            const SizedBox(height: 12),
            InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => setState(() => _acknowledged = !_acknowledged),
              child: Row(
                children: <Widget>[
                  Checkbox(
                    value: _acknowledged,
                    onChanged: (bool? value) =>
                        setState(() => _acknowledged = value ?? false),
                  ),
                  Expanded(
                    child: Text(
                      widget.counts.local > 0
                          ? l10n.comicDetailDeleteLocalAcknowledge
                          : l10n.comicPurgeRemoteAcknowledge,
                      style: theme.typeScale.bodyMedium.copyWith(
                        color: scheme.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
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
          onPressed: canConfirm ? () => Navigator.of(context).pop(true) : null,
          style: M3EButtonStyle.filled,
          decoration: M3EButtonDecoration.styleFrom(
            textStyle: actionLabelStyle,
            backgroundColor: scheme.error,
            foregroundColor: scheme.onError,
            disabledBackgroundColor: scheme.onSurface.withValues(alpha: 0.12),
            disabledForegroundColor: scheme.onSurface.withValues(alpha: 0.38),
          ),
          label: Text(l10n.trashPurge),
        ),
      ],
    );
  }

  String _message(AppLocalizations l10n) {
    final String singleTitle = widget.title ?? '';
    return switch (purgeConfirmCopyFor(widget.counts)) {
      PurgeConfirmCopy.singleLocal => l10n.comicDetailDeleteLocalConfirm(
        singleTitle,
      ),
      PurgeConfirmCopy.singleRemote => l10n.comicDetailDeleteRemoteConfirm(
        singleTitle,
      ),
      PurgeConfirmCopy.batchLocal => l10n.comicPurgeLocalBatchConfirm(
        widget.counts.local,
      ),
      PurgeConfirmCopy.batchRemote => l10n.comicPurgeRemoteBatchConfirm(
        widget.counts.remote,
      ),
      PurgeConfirmCopy.mixed => l10n.comicPurgeMixedConfirm(
        widget.counts.local,
        widget.counts.remote,
      ),
    };
  }
}
