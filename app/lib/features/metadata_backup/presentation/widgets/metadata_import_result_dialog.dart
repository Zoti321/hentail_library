import 'package:flutter/material.dart';
import 'package:hentai_library/core/l10n/app_localizations.dart';
import 'package:hentai_library/core/l10n/app_localizations_x.dart';
import 'package:hentai_library/features/metadata_backup/domain/metadata_import_result.dart';
import 'package:hentai_library/design-system/design_system.dart';
import 'package:hentai_library/features/metadata_backup/presentation/widgets/metadata_import_dialog_parts.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

export 'package:hentai_library/features/metadata_backup/presentation/widgets/metadata_import_dialog_parts.dart';

class MetadataImportResultDialog extends StatelessWidget {
  const MetadataImportResultDialog({required this.result, super.key});

  final MetadataImportResult result;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    return M3EDialog(
      title: l10n.settingsMetadataBackupImportResultTitle,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          MetadataImportSummaryLine(
            label: l10n.settingsMetadataBackupImportResultApplied,
            value: result.applied.toString(),
          ),
          MetadataImportSummaryLine(
            label: l10n.settingsMetadataBackupImportResultSkippedNotFound,
            value: result.skippedNotFound.toString(),
          ),
          MetadataImportSummaryLine(
            label: l10n.settingsMetadataBackupImportResultSkippedAmbiguous,
            value: result.skippedAmbiguous.toString(),
          ),
          if (result.errors.isNotEmpty) ...<Widget>[
            const SizedBox(height: 8),
            Text(
              l10n.settingsMetadataBackupImportResultErrors,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            for (final String error in result.errors)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text('• $error'),
              ),
          ],
        ],
      ),
      bottomDivider: true,
      actions: <Widget>[
        M3EButton(
          onPressed: () => Navigator.of(context).pop(),
          style: M3EButtonStyle.filled,
          decoration: M3EButtonDecoration(
            textStyle: labButtonLabelStyle(
              M3ETheme.of(context),
              M3EButtonSize.sm,
            ),
          ),
          label: Text(l10n.commonOk),
        ),
      ],
    );
  }
}
