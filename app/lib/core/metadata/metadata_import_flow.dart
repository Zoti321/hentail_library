import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:hentai_library/core/l10n/app_localizations.dart';
import 'package:hentai_library/core/l10n/app_localizations_x.dart';
import 'package:hentai_library/core/logging/app_log.dart';
import 'package:hentai_library/core/metadata/metadata_backup_bytes.dart';
import 'package:hentai_library/data/adapters/metadata_backup_frb_adapter.dart';
import 'package:hentai_library/src/rust/api/metadata_backup.dart';
import 'package:hentai_library/ui/core/widgets/feedback/custom_toast.dart';
import 'package:hentai_library/ui/core/widgets/overlays/dialog/hentai_dialog.dart';

typedef MetadataPeekInvoker =
    MetadataBackupManifestDto Function(Uint8List bytes);

typedef MetadataPreviewInvoker =
    PreviewImportComicMetadataResultDto Function(Uint8List bytes);

typedef MetadataImportInvoker =
    ImportComicMetadataResultDto Function(Uint8List bytes);

/// 手动导入 Comic 用户元数据：选文件 → peek → 预演 → 确认 → import → 结果摘要。
Future<void> runMetadataImportFlow(
  BuildContext context, {
  MetadataPeekInvoker? peekInvoker,
  MetadataPreviewInvoker? previewInvoker,
  MetadataImportInvoker? importInvoker,
}) async {
  final AppLocalizations l10n = context.l10n;
  final FilePickerResult? picked = await FilePicker.platform.pickFiles(
    dialogTitle: l10n.settingsMetadataBackupImportPickDialogTitle,
    type: FileType.custom,
    allowedExtensions: <String>['hlmeta.json', 'gz'],
  );
  if (picked == null || picked.files.isEmpty || !context.mounted) {
    return;
  }

  final PlatformFile file = picked.files.single;
  final String? path = file.path;
  if (path == null || !isMetadataBackupFilePath(path)) {
    if (context.mounted) {
      showErrorToast(context, l10n.settingsMetadataBackupImportInvalidFile);
    }
    return;
  }

  try {
    final List<int> rawBytes = file.bytes ?? await File(path).readAsBytes();
    final Uint8List jsonBytes = decodeMetadataBackupFileBytes(rawBytes, path);

    final MetadataPeekInvoker peek = peekInvoker ??
        (Uint8List bytes) => const MetadataBackupFrbAdapter().peek(bytes: bytes);
    final MetadataBackupManifestDto manifest = peek(jsonBytes);

    if (!context.mounted) {
      return;
    }

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) => PopScope(
        canPop: false,
        child: HentaiDialog(
          title: l10n.settingsMetadataBackupImportPreviewRunningTitle,
          content: Row(
            children: <Widget>[
              const CircularProgressIndicator(),
              const SizedBox(width: 16),
              Expanded(
                child: Text(l10n.settingsMetadataBackupImportPreviewRunningBody),
              ),
            ],
          ),
          actions: const <Widget>[],
          scrollableContent: false,
          showFooterDivider: false,
        ),
      ),
    );

    final MetadataPreviewInvoker preview = previewInvoker ??
        (Uint8List bytes) =>
            const MetadataBackupFrbAdapter().preview(bytes: bytes);
    final PreviewImportComicMetadataResultDto previewResult = preview(jsonBytes);

    if (context.mounted) {
      Navigator.of(context, rootNavigator: true).pop();
    }

    if (!context.mounted) {
      return;
    }

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => MetadataImportConfirmDialog(
        manifest: manifest,
        preview: previewResult,
      ),
    );
    if (confirmed != true || !context.mounted) {
      return;
    }

    if (!context.mounted) {
      return;
    }
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) => PopScope(
        canPop: false,
        child: HentaiDialog(
          title: l10n.settingsMetadataBackupImportRunningTitle,
          content: Row(
            children: <Widget>[
              const CircularProgressIndicator(),
              const SizedBox(width: 16),
              Expanded(child: Text(l10n.settingsMetadataBackupImportRunningBody)),
            ],
          ),
          actions: const <Widget>[],
          scrollableContent: false,
          showFooterDivider: false,
        ),
      ),
    );

    final MetadataImportInvoker import = importInvoker ??
        (Uint8List bytes) =>
            const MetadataBackupFrbAdapter().import(bytes: bytes);
    final ImportComicMetadataResultDto result = import(jsonBytes);

    if (context.mounted) {
      Navigator.of(context, rootNavigator: true).pop();
    }

    if (!context.mounted) {
      return;
    }

    await showDialog<void>(
      context: context,
      builder: (BuildContext context) => MetadataImportResultDialog(
        result: result,
      ),
    );
  } catch (e, st) {
    logError(AppLog.core('metadata_backup'), '导入元数据失败', e, st);
    if (context.mounted) {
      Navigator.of(context, rootNavigator: true).maybePop();
      showErrorToast(context, e);
    }
  }
}

class MetadataImportConfirmDialog extends StatefulWidget {
  const MetadataImportConfirmDialog({
    required this.manifest,
    required this.preview,
    super.key,
  });

  final MetadataBackupManifestDto manifest;
  final PreviewImportComicMetadataResultDto preview;

  @override
  State<MetadataImportConfirmDialog> createState() =>
      _MetadataImportConfirmDialogState();
}

class _MetadataImportConfirmDialogState extends State<MetadataImportConfirmDialog> {
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
    final PreviewImportComicMetadataResultDto preview = widget.preview;
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
            Theme(
              data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                tilePadding: EdgeInsets.zero,
                initiallyExpanded: _detailsExpanded,
                onExpansionChanged: (bool expanded) {
                  setState(() => _detailsExpanded = expanded);
                },
                title: Text(
                  l10n.settingsMetadataBackupImportConfirmDetailsTitle,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                children: <Widget>[
                  for (final WouldApplySampleDto sample
                      in preview.samplesWouldApply)
                    _PreviewSampleLine(
                      primary: sample.title,
                      secondary: _wouldApplySecondary(l10n, sample),
                      path: sample.path,
                    ),
                  for (final NotFoundSampleDto sample in preview.samplesNotFound)
                    _PreviewSampleLine(
                      primary: sample.title,
                      secondary: sample.comicId,
                      path: sample.path,
                    ),
                  for (final AmbiguousSampleDto sample
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

  bool _hasPreviewDetails(PreviewImportComicMetadataResultDto preview) {
    return preview.samplesWouldApply.isNotEmpty ||
        preview.samplesNotFound.isNotEmpty ||
        preview.samplesAmbiguous.isNotEmpty;
  }

  String _wouldApplySecondary(
    AppLocalizations l10n,
    WouldApplySampleDto sample,
  ) {
    final StringBuffer buffer = StringBuffer(sample.matchedComicId);
    final MatchTierDto? tier = sample.matchTier;
    if (tier != null) {
      buffer.write(' · ');
      buffer.write(
        switch (tier) {
          MatchTierDto.path =>
            l10n.settingsMetadataBackupImportPreviewMatchTierPath,
          MatchTierDto.libraryRelative =>
            l10n.settingsMetadataBackupImportPreviewMatchTierLibraryRelative,
        },
      );
    }
    return buffer.toString();
  }
}

class MetadataImportResultDialog extends StatelessWidget {
  const MetadataImportResultDialog({required this.result, super.key});

  final ImportComicMetadataResultDto result;

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

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        label,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
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
