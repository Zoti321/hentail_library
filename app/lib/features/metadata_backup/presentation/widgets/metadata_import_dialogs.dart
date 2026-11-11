import 'package:flutter/material.dart';
import 'package:hentai_library/core/l10n/app_localizations.dart';
import 'package:hentai_library/core/l10n/app_localizations_x.dart';
import 'package:hentai_library/features/metadata_backup/domain/metadata_backup_manifest.dart';
import 'package:hentai_library/features/metadata_backup/domain/metadata_import_match_tier.dart';
import 'package:hentai_library/features/metadata_backup/domain/metadata_import_preview.dart';
import 'package:hentai_library/features/metadata_backup/domain/metadata_import_result.dart';
import 'package:hentai_library/design-system/design_system.dart';
import 'package:hentai_library/shared/ui/widgets/overlays/dialog/hentai_dialog.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

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

    return HentaiDialog(
      title: l10n.settingsMetadataBackupImportConfirmTitle,
      width: 480,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(l10n.settingsMetadataBackupImportConfirmWarning),
          const SizedBox(height: 16),
          _SectionHeading(
            label: l10n.settingsMetadataBackupImportConfirmManifestSection,
          ),
          _SummaryLine(
            label: l10n.settingsMetadataBackupImportManifestSchema,
            value: widget.manifest.schemaVersion.toString(),
          ),
          _SummaryLine(
            label: l10n.settingsMetadataBackupImportManifestExportedAt,
            value: widget.manifest.exportedAt,
          ),
          _SummaryLine(
            label: l10n.settingsMetadataBackupImportManifestComicCount,
            value: widget.manifest.comicCount.toString(),
          ),
          _SummaryLine(
            label: l10n.settingsMetadataBackupImportManifestAppVersion,
            value: widget.manifest.appVersion,
          ),
          const SizedBox(height: 12),
          _SectionHeading(
            label: l10n.settingsMetadataBackupImportConfirmPreviewSection,
          ),
          _SummaryLine(
            label: l10n.settingsMetadataBackupImportPreviewWouldApply,
            value: preview.wouldApply.toString(),
          ),
          _SummaryLine(
            label: l10n.settingsMetadataBackupImportPreviewSkippedNotFound,
            value: preview.skippedNotFound.toString(),
          ),
          _SummaryLine(
            label: l10n.settingsMetadataBackupImportPreviewSkippedAmbiguous,
            value: preview.skippedAmbiguous.toString(),
          ),
          _SummaryLine(
            label: l10n.settingsMetadataBackupImportPreviewOrphanFacets,
            value: preview.wouldUpsertOrphanFacetCount.toString(),
          ),
          if (_hasPreviewDetails(preview)) ...<Widget>[
            const SizedBox(height: 8),
            _MetadataImportDetailsAccordion(
              expanded: _detailsExpanded,
              title: l10n.settingsMetadataBackupImportConfirmDetailsTitle,
              onExpandedChanged: (bool expanded) {
                setState(() => _detailsExpanded = expanded);
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  for (final MetadataImportWouldApplySample sample
                      in preview.samplesWouldApply)
                    _PreviewSampleLine(
                      primary: sample.title,
                      secondary: _wouldApplySecondary(l10n, sample),
                      path: sample.path,
                    ),
                  for (final MetadataImportNotFoundSample sample
                      in preview.samplesNotFound)
                    _PreviewSampleLine(
                      primary: sample.title,
                      secondary: sample.comicId,
                      path: sample.path,
                    ),
                  for (final MetadataImportAmbiguousSample sample
                      in preview.samplesAmbiguous)
                    _PreviewSampleLine(
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
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(l10n.commonCancel),
        ),
        FilledButton(
          onPressed: canImport ? () => Navigator.of(context).pop(true) : null,
          child: Text(
            canImport
                ? l10n.settingsMetadataBackupImportConfirmActionWithCount(
                    preview.wouldApply,
                  )
                : l10n.settingsMetadataBackupImportConfirmActionDisabled,
          ),
        ),
      ],
    );
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

class MetadataImportResultDialog extends StatelessWidget {
  const MetadataImportResultDialog({required this.result, super.key});

  final MetadataImportResult result;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    return HentaiDialog(
      title: l10n.settingsMetadataBackupImportResultTitle,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _SummaryLine(
            label: l10n.settingsMetadataBackupImportResultApplied,
            value: result.applied.toString(),
          ),
          _SummaryLine(
            label: l10n.settingsMetadataBackupImportResultSkippedNotFound,
            value: result.skippedNotFound.toString(),
          ),
          _SummaryLine(
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
      actions: <Widget>[
        FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.commonOk),
        ),
      ],
    );
  }
}

class _MetadataImportDetailsAccordion extends StatelessWidget {
  const _MetadataImportDetailsAccordion({
    required this.expanded,
    required this.title,
    required this.onExpandedChanged,
    required this.child,
  });

  final bool expanded;
  final String title;
  final ValueChanged<bool> onExpandedChanged;
  final Widget child;

  static const Duration _duration = Duration(milliseconds: 200);
  static const Curve _curve = Curves.easeOutCubic;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final AppThemeTokens tokens = context.tokens;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => onExpandedChanged(!expanded),
            hoverColor: theme.hoverColor,
            splashColor: theme.splashColor,
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: tokens.spacing.sm),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  AnimatedRotation(
                    turns: expanded ? 0.5 : 0,
                    duration: _duration,
                    curve: _curve,
                    child: Icon(
                      LucideIcons.chevronDown,
                      size: 16,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        AnimatedSize(
          duration: _duration,
          curve: _curve,
          alignment: Alignment.topCenter,
          child: expanded ? child : const SizedBox.shrink(),
        ),
      ],
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        label,
        style: Theme.of(context).textTheme.titleSmall
            ?.copyWith(fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _SummaryLine extends StatelessWidget {
  const _SummaryLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: RichText(
        text: TextSpan(
          style: DefaultTextStyle.of(context).style,
          children: <TextSpan>[
            TextSpan(
              text: '$label: ',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }
}

class _PreviewSampleLine extends StatelessWidget {
  const _PreviewSampleLine({
    required this.primary,
    required this.secondary,
    required this.path,
  });

  final String primary;
  final String secondary;
  final String path;

  @override
  Widget build(BuildContext context) {
    final String displayPath = ellipsisMiddlePath(path);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(primary, style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(secondary, style: Theme.of(context).textTheme.bodySmall),
          Tooltip(
            message: path,
            child: Text(
              displayPath,
              style: Theme.of(context).textTheme.bodySmall,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

/// 长路径中间省略，保留首尾以便识别。
String ellipsisMiddlePath(String path, {int maxLength = 56}) {
  if (path.length <= maxLength) {
    return path;
  }
  final int keep = (maxLength - 1) ~/ 2;
  return '${path.substring(0, keep)}…${path.substring(path.length - keep)}';
}
