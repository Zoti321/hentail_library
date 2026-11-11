import 'package:flutter/material.dart';
import 'package:hentai_library/core/l10n/app_localizations.dart';
import 'package:hentai_library/core/l10n/app_localizations_x.dart';
import 'package:hentai_library/shared/ui/patterns/dialog/lab_dialog_presenter.dart';
import 'package:hentai_library/design-system/design_system.dart';
import 'package:hentai_library/features/comic_trash/domain/comic_purge_strategy.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

/// 永久删除（Comic purge）前的危险确认框：MD3E 壳 + 勾选闸门（ADR-0023）。
///
/// 单本传入 [title]；批量或「全部永久删除」传 null。混选时分别展示 Local / Remote 数量。
Future<bool> showTrashPurgeConfirmDialog({
  required BuildContext context,
  String? title,
  required PurgeTargetCounts counts,
}) async {
  final bool? confirmed = await LabDialogPresenter.showBasic<bool>(
    context,
    dialog: TrashPurgeConfirmDialog(title: title, counts: counts),
  );
  return confirmed ?? false;
}

class TrashPurgeConfirmDialog extends StatefulWidget {
  const TrashPurgeConfirmDialog({super.key, this.title, required this.counts});

  final String? title;
  final PurgeTargetCounts counts;

  @override
  State<TrashPurgeConfirmDialog> createState() =>
      _TrashPurgeConfirmDialogState();
}

class _TrashPurgeConfirmDialogState extends State<TrashPurgeConfirmDialog> {
  bool _acknowledged = false;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final M3EThemeData theme = M3ETheme.of(context);
    final M3EColorScheme scheme = theme.colorScheme;
    final TextStyle actionLabelStyle = labButtonLabelStyle(
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
