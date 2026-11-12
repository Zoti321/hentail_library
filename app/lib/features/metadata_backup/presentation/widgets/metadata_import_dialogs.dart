import 'package:flutter/material.dart';
import 'package:hentai_library/core/l10n/app_localizations.dart';
import 'package:hentai_library/core/l10n/app_localizations_x.dart';
import 'package:hentai_library/features/metadata_backup/domain/metadata_backup_manifest.dart';
import 'package:hentai_library/features/metadata_backup/domain/metadata_import_match_tier.dart';
import 'package:hentai_library/features/metadata_backup/domain/metadata_import_preview.dart';
import 'package:hentai_library/design-system/design_system.dart';
import 'package:hentai_library/features/metadata_backup/presentation/widgets/metadata_import_dialog_parts.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

export 'package:hentai_library/features/metadata_backup/presentation/widgets/metadata_import_result_dialog.dart';

class MetadataImportConfirmDialog extends StatefulWidget {
  const MetadataImportConfirmDialog({
    required this.manifest,
    required this.preview,
    super.key,
  });

  final MetadataBackupManifest manifest;
  final MetadataImportPreview preview;

  @override
  State<MetadataImportConfirmDialog> createState() =>
      _MetadataImportConfirmDialogState();
}

class _MetadataImportConfirmDialogState
    extends State<MetadataImportConfirmDialog> {
  late bool _detailsExpanded;

  @override
  void initState() {
    super.initState();
    _detailsExpanded =
        widget.preview.skippedNotFound + widget.preview.skippedAmbiguous > 0;
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final MetadataImportPreview preview = widget.preview;
    final bool canImport = preview.wouldApply > 0;

    return M3EDialog(
      title: l10n.settingsMetadataBackupImportConfirmTitle,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(l10n.settingsMetadataBackupImportConfirmWarning),
          const SizedBox(height: 16),
          MetadataImportSectionHeading(
            label: l10n.settingsMetadataBackupImportConfirmManifestSection,
          ),
          MetadataImportSummaryLine(
            label: l10n.settingsMetadataBackupImportManifestSchema,
            value: widget.manifest.schemaVersion.toString(),
          ),
          MetadataImportSummaryLine(
            label: l10n.settingsMetadataBackupImportManifestExportedAt,
            value: widget.manifest.exportedAt,
          ),
          MetadataImportSummaryLine(
            label: l10n.settingsMetadataBackupImportManifestComicCount,
            value: widget.manifest.comicCount.toString(),
          ),
          MetadataImportSummaryLine(
            label: l10n.settingsMetadataBackupImportManifestAppVersion,
            value: widget.manifest.appVersion,
          ),
          const SizedBox(height: 12),
          MetadataImportSectionHeading(
            label: l10n.settingsMetadataBackupImportConfirmPreviewSection,
          ),
          MetadataImportSummaryLine(
            label: l10n.settingsMetadataBackupImportPreviewWouldApply,
            value: preview.wouldApply.toString(),
          ),
          MetadataImportSummaryLine(
            label: l10n.settingsMetadataBackupImportPreviewSkippedNotFound,
            value: preview.skippedNotFound.toString(),
          ),
          MetadataImportSummaryLine(
            label: l10n.settingsMetadataBackupImportPreviewSkippedAmbiguous,
            value: preview.skippedAmbiguous.toString(),
          ),
          MetadataImportSummaryLine(
            label: l10n.settingsMetadataBackupImportPreviewOrphanFacets,
            value: preview.wouldUpsertOrphanFacetCount.toString(),
          ),
          if (_hasPreviewDetails(preview)) ...<Widget>[
            const SizedBox(height: 8),
            MetadataImportDetailsAccordion(
              expanded: _detailsExpanded,
              title: l10n.settingsMetadataBackupImportConfirmDetailsTitle,
              onExpandedChanged: _handleDetailsExpanded,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  for (final MetadataImportWouldApplySample sample
                      in preview.samplesWouldApply)
                    MetadataImportPreviewSampleLine(
                      primary: sample.title,
                      secondary: _wouldApplySecondary(l10n, sample),
                      path: sample.path,
                    ),
                  for (final MetadataImportNotFoundSample sample
                      in preview.samplesNotFound)
                    MetadataImportPreviewSampleLine(
                      primary: sample.title,
                      secondary: sample.comicId,
                      path: sample.path,
                    ),
                  for (final MetadataImportAmbiguousSample sample
                      in preview.samplesAmbiguous)
                    MetadataImportPreviewSampleLine(
                      primary: sample.title,
                      secondary:
                          '${sample.comicId} → ${sample.candidateComicIds.join(', ')}',
                      path: sample.path,
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
      bottomDivider: true,
      actions: <Widget>[
        DialogActionBar(
          onCancel: () => Navigator.of(context).pop(false),
          onConfirm: () => Navigator.of(context).pop(true),
          cancelLabel: l10n.commonCancel,
          confirmEnabled: canImport,
          confirmLabel: canImport
              ? l10n.settingsMetadataBackupImportConfirmActionWithCount(
                  preview.wouldApply,
                )
              : l10n.settingsMetadataBackupImportConfirmActionDisabled,
        ),
      ],
    );
  }

  void _handleDetailsExpanded(bool expanded) {
    setState(() => _detailsExpanded = expanded);
  }

  bool _hasPreviewDetails(MetadataImportPreview preview) {
    return preview.samplesWouldApply.isNotEmpty ||
        preview.samplesNotFound.isNotEmpty ||
        preview.samplesAmbiguous.isNotEmpty;
  }

  String _wouldApplySecondary(
    AppLocalizations l10n,
    MetadataImportWouldApplySample sample,
  ) {
    final StringBuffer buffer = StringBuffer(sample.matchedComicId);
    final MetadataImportMatchTier? tier = sample.matchTier;
    if (tier != null) {
      buffer.write(' · ');
      buffer.write(switch (tier) {
        MetadataImportMatchTier.path =>
          l10n.settingsMetadataBackupImportPreviewMatchTierPath,
        MetadataImportMatchTier.libraryRelative =>
          l10n.settingsMetadataBackupImportPreviewMatchTierLibraryRelative,
      });
    }
    return buffer.toString();
  }
}
