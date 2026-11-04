import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:hentai_library/core/l10n/app_localizations.dart';
import 'package:hentai_library/core/l10n/app_localizations_x.dart';
import 'package:hentai_library/core/logging/app_log.dart';
import 'package:hentai_library/features/metadata_backup/application/metadata_import_use_case.dart';
import 'package:hentai_library/features/metadata_backup/data/repositories/metadata_backup_repository_impl.dart';
import 'package:hentai_library/features/metadata_backup/domain/metadata_backup_bytes.dart';
import 'package:hentai_library/features/metadata_backup/domain/metadata_backup_manifest.dart';
import 'package:hentai_library/features/metadata_backup/domain/metadata_import_preview.dart';
import 'package:hentai_library/features/metadata_backup/domain/metadata_import_result.dart';
import 'package:hentai_library/features/metadata_backup/presentation/widgets/metadata_import_dialogs.dart';
import 'package:hentai_library/shared/ui/widgets/feedback/app_snackbar.dart';
import 'package:hentai_library/shared/ui/widgets/overlays/dialog/hentai_dialog.dart';

export 'widgets/metadata_import_dialogs.dart';

/// 手动导入 Comic 用户元数据：选文件 → peek → 预演 → 确认 → import → 结果摘要。
Future<void> runMetadataImportFlow(
  BuildContext context, {
  MetadataImportUseCase? importUseCase,
}) async {
  final AppLocalizations l10n = context.l10n;
  final MetadataImportUseCase useCase =
      importUseCase ??
      MetadataImportUseCase(const MetadataBackupRepositoryImpl());

  final FilePickerResult? picked = await FilePicker.pickFiles(
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
      showErrorSnackbar(context, l10n.settingsMetadataBackupImportInvalidFile);
    }
    return;
  }

  try {
    final List<int> rawBytes = file.bytes ?? await File(path).readAsBytes();
    final jsonBytes = useCase.decodeBackupFileBytes(rawBytes, path);
    final MetadataBackupManifest manifest = useCase.peekManifest(jsonBytes);

    if (!context.mounted) {
      return;
    }

    await _showBlockingProgressDialog(
      context,
      title: l10n.settingsMetadataBackupImportPreviewRunningTitle,
      body: l10n.settingsMetadataBackupImportPreviewRunningBody,
    );

    final MetadataImportPreview previewResult = useCase.previewImport(
      jsonBytes,
    );

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

    await _showBlockingProgressDialog(
      context,
      title: l10n.settingsMetadataBackupImportRunningTitle,
      body: l10n.settingsMetadataBackupImportRunningBody,
    );

    final MetadataImportResult result = useCase.importMetadata(jsonBytes);

    if (context.mounted) {
      Navigator.of(context, rootNavigator: true).pop();
    }

    if (!context.mounted) {
      return;
    }

    await showDialog<void>(
      context: context,
      builder: (BuildContext context) =>
          MetadataImportResultDialog(result: result),
    );
  } catch (e, st) {
    logError(AppLog.core('metadata_backup'), '导入元数据失败', e, st);
    if (context.mounted) {
      Navigator.of(context, rootNavigator: true).maybePop();
      showErrorSnackbar(context, e);
    }
  }
}

Future<void> _showBlockingProgressDialog(
  BuildContext context, {
  required String title,
  required String body,
}) {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) => PopScope(
      canPop: false,
      child: HentaiDialog(
        title: title,
        content: Row(
          children: <Widget>[
            const CircularProgressIndicator(),
            const SizedBox(width: 16),
            Expanded(child: Text(body)),
          ],
        ),
        actions: const <Widget>[],
        scrollableContent: false,
        showFooterDivider: false,
      ),
    ),
  );
}
