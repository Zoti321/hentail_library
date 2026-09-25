import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:hentai_library/core/l10n/app_localizations.dart';
import 'package:hentai_library/core/l10n/app_localizations_x.dart';
import 'package:hentai_library/core/logging/app_log.dart';
import 'package:hentai_library/core/metadata/metadata_export_options.dart';
import 'package:hentai_library/data/adapters/metadata_backup_frb_adapter.dart';
import 'package:hentai_library/src/rust/api/metadata_backup.dart';
import 'package:hentai_library/ui/core/widgets/feedback/custom_toast.dart';
import 'package:hentai_library/ui/core/widgets/overlays/dialog/hentai_dialog.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;

typedef MetadataExportInvoker =
    Uint8List Function(ExportComicMetadataOptionsDto options);

/// 手动导出 Comic 用户元数据：选项 dialog → 另存为 → FRB export → Toast。
Future<void> runMetadataExportFlow(
  BuildContext context, {
  required MetadataExportOptions initialOptions,
  MetadataExportInvoker? exportInvoker,
}) async {
  final MetadataExportOptions? options = await showDialog<MetadataExportOptions>(
    context: context,
    builder: (BuildContext context) =>
        MetadataExportOptionsDialog(initialOptions: initialOptions),
  );
  if (options == null || !context.mounted) {
    return;
  }

  final AppLocalizations l10n = context.l10n;
  final String extension = options.gzip ? 'hlmeta.json.gz' : 'hlmeta.json';
  final String defaultName =
      'metadata-${DateFormat('yyyyMMdd-HHmmss').format(DateTime.now())}.$extension';
  final String? savePath = await FilePicker.platform.saveFile(
    dialogTitle: l10n.settingsMetadataBackupExportSaveDialogTitle,
    fileName: defaultName,
    type: FileType.custom,
    allowedExtensions: <String>[extension],
  );
  if (savePath == null || !context.mounted) {
    return;
  }

  try {
    final ExportComicMetadataOptionsDto dto = ExportComicMetadataOptionsDto(
      libraryId: options.currentLibraryOnly ? options.libraryId : null,
      includeOrphanFacets: options.includeOrphanFacets,
    );
    final MetadataExportInvoker invoke = exportInvoker ??
        (ExportComicMetadataOptionsDto options) =>
            const MetadataBackupFrbAdapter().export(options: options);
    final Uint8List raw = invoke(dto);
    final List<int> output = options.gzip ? GZipCodec().encode(raw) : raw;
    final String outputPath = _ensureExtension(savePath, extension);
    await File(outputPath).writeAsBytes(output, flush: true);

    if (context.mounted) {
      showSuccessToast(
        context,
        l10n.settingsMetadataBackupExportSuccess(p.basename(outputPath)),
      );
    }
  } catch (e, st) {
    logError(AppLog.core('metadata_backup'), '导出元数据失败', e, st);
    if (context.mounted) {
      showErrorToast(context, e);
    }
  }
}

String _ensureExtension(String savePath, String extension) {
  final String lower = savePath.toLowerCase();
  if (lower.endsWith('.${extension.toLowerCase()}')) {
    return savePath;
  }
  if (lower.endsWith('.json') && extension == 'hlmeta.json') {
    return savePath;
  }
  return '$savePath.$extension';
}

class MetadataExportOptionsDialog extends StatefulWidget {
  const MetadataExportOptionsDialog({required this.initialOptions, super.key});

  final MetadataExportOptions initialOptions;

  @override
  State<MetadataExportOptionsDialog> createState() =>
      _MetadataExportOptionsDialogState();
}

class _MetadataExportOptionsDialogState extends State<MetadataExportOptionsDialog> {
  late bool _gzip;
  late bool _includeOrphanFacets;
  late bool _currentLibraryOnly;

  @override
  void initState() {
    super.initState();
    _gzip = widget.initialOptions.gzip;
    _includeOrphanFacets = widget.initialOptions.includeOrphanFacets;
    _currentLibraryOnly = widget.initialOptions.currentLibraryOnly;
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    return HentaiDialog(
      title: l10n.settingsMetadataBackupExportDialogTitle,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.settingsMetadataBackupExportGzipLabel),
            value: _gzip,
            onChanged: (bool value) => setState(() => _gzip = value),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.settingsMetadataBackupExportOrphanFacetsLabel),
            value: _includeOrphanFacets,
            onChanged: (bool value) =>
                setState(() => _includeOrphanFacets = value),
          ),
          if (widget.initialOptions.libraryId != null)
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.settingsMetadataBackupExportCurrentLibraryLabel),
              value: _currentLibraryOnly,
              onChanged: (bool value) =>
                  setState(() => _currentLibraryOnly = value),
            ),
        ],
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.commonCancel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(
            MetadataExportOptions(
              gzip: _gzip,
              includeOrphanFacets: _includeOrphanFacets,
              currentLibraryOnly: _currentLibraryOnly,
              libraryId: widget.initialOptions.libraryId,
            ),
          ),
          child: Text(l10n.settingsMetadataBackupExportConfirm),
        ),
      ],
    );
  }
}
