import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hentai_library/core/l10n/app_localizations.dart';
import 'package:hentai_library/core/l10n/app_localizations_x.dart';
import 'package:hentai_library/shared/domain/comic_trash/comic_purge_policy.dart';
import 'package:hentai_library/shared/ui/theme/theme.dart';
import 'package:hentai_library/shared/ui/widgets/actions/destructive_filled_button.dart';
import 'package:hentai_library/shared/ui/widgets/overlays/dialog/hentai_dialog.dart';

/// Comic purge 前的危险确认对话框（与标签/路径等确认框同一套 HentaiDialog 壳）。
///
/// 一律须勾选闸门才能确认（ADR-0023）；含 Local 时勾选文案强调删盘，
/// 纯 Remote 时勾选文案强调从库中永久移除。混选时分别显示两类数量。
class ComicConfirmPurgeDialog extends HookWidget {
  /// 单本 Comic purge。
  const ComicConfirmPurgeDialog({
    super.key,
    required String this.title,
    required bool isLocal,
  }) : counts = isLocal ? (local: 1, remote: 0) : (local: 0, remote: 1);

  /// 多本 Comic purge（多选或「全部永久删除」）。
  const ComicConfirmPurgeDialog.batch({super.key, required this.counts})
    : title = null;

  final String? title;
  final PurgeTargetCounts counts;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final ColorScheme cs = Theme.of(context).colorScheme;
    final acknowledgement = useState(false);
    final bool needsAcknowledgement = purgeRequiresAcknowledgement(counts);
    final bool canConfirm = !needsAcknowledgement || acknowledgement.value;
    return HentaiDialog(
      title: l10n.comicPurgeTitle,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            _message(l10n),
            style: TextStyle(fontSize: 14, color: context.hentai.textSecondary),
          ),
          if (needsAcknowledgement) ...<Widget>[
            const SizedBox(height: 12),
            CheckboxListTile(
              value: acknowledgement.value,
              onChanged: (bool? value) =>
                  acknowledgement.value = value ?? false,
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              title: Text(
                counts.local > 0
                    ? l10n.comicDetailDeleteLocalAcknowledge
                    : l10n.comicPurgeRemoteAcknowledge,
                style: TextStyle(
                  fontSize: 14,
                  color: context.hentai.textPrimary,
                ),
              ),
            ),
          ],
        ],
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(l10n.commonCancel),
        ),
        DestructiveFilledButton(
          onPressed: canConfirm ? () => Navigator.of(context).pop(true) : null,
          child: Text(l10n.trashPurge),
        ),
      ],
    );
  }

  String _message(AppLocalizations l10n) {
    final String singleTitle = title ?? '';
    return switch (purgeConfirmCopyFor(counts)) {
      PurgeConfirmCopy.singleLocal => l10n.comicDetailDeleteLocalConfirm(
        singleTitle,
      ),
      PurgeConfirmCopy.singleRemote => l10n.comicDetailDeleteRemoteConfirm(
        singleTitle,
      ),
      PurgeConfirmCopy.batchLocal => l10n.comicPurgeLocalBatchConfirm(
        counts.local,
      ),
      PurgeConfirmCopy.batchRemote => l10n.comicPurgeRemoteBatchConfirm(
        counts.remote,
      ),
      PurgeConfirmCopy.mixed => l10n.comicPurgeMixedConfirm(
        counts.local,
        counts.remote,
      ),
    };
  }
}
