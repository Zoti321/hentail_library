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

typedef MetadataImportInvoker =
    ImportComicMetadataResultDto Function(Uint8List bytes);

/// 手动导入 Comic 用户元数据：选文件 → peek → 确认 → import → 结果摘要。
Future<void> runMetadataImportFlow(
  BuildContext context, {
  MetadataPeekInvoker? peekInvoker,
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

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => MetadataImportConfirmDialog(
        manifest: manifest,
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

class MetadataImportConfirmDialog extends StatelessWidget {
  const MetadataImportConfirmDialog({required this.manifest, super.key});

  final MetadataBackupManifestDto manifest;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    return HentaiDialog(
      title: l10n.settingsMetadataBackupImportConfirmTitle,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(l10n.settingsMetadataBackupImportConfirmWarning),
          const SizedBox(height: 12),
          _SummaryLine(
            label: l10n.settingsMetadataBackupImportManifestSchema,
            value: manifest.schemaVersion.toString(),
          ),
          _SummaryLine(
            label: l10n.settingsMetadataBackupImportManifestExportedAt,
            value: manifest.exportedAt,
          ),
          _SummaryLine(
            label: l10n.settingsMetadataBackupImportManifestComicCount,
            value: manifest.comicCount.toString(),
          ),
          _SummaryLine(
            label: l10n.settingsMetadataBackupImportManifestAppVersion,
            value: manifest.appVersion,
          ),
        ],
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(l10n.commonCancel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(l10n.settingsMetadataBackupImportConfirmAction),
        ),
      ],
    );
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
