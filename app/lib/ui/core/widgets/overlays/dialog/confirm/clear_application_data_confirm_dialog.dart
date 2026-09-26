import 'package:flutter/material.dart';
import 'package:hentai_library/core/app_data/app_data_wipe_flow.dart';
import 'package:hentai_library/core/l10n/app_localizations_x.dart';
import 'package:hentai_library/ui/core/widgets/actions/destructive_filled_button.dart';
import 'package:hentai_library/ui/core/widgets/overlays/dialog/hentai_dialog.dart';

class ClearApplicationDataConfirmDialog extends StatelessWidget {
  const ClearApplicationDataConfirmDialog({this.recentBackupAt, super.key});

  final DateTime? recentBackupAt;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final String recentBackupText = recentBackupAt == null
        ? l10n.confirmClearApplicationDataRecentBackupEmpty
        : l10n.confirmClearApplicationDataRecentBackup(
            formatRecentMetadataBackupAt(recentBackupAt!),
          );

    return HentaiDialog(
      title: l10n.confirmClearApplicationDataTitle,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(l10n.confirmClearApplicationDataContent),
          const SizedBox(height: 12),
          Text(
            recentBackupText,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          style: TextButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: Text(l10n.commonCancel),
        ),
        const SizedBox(width: 8),
        DestructiveFilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(l10n.commonClear),
        ),
      ],
    );
  }
}
