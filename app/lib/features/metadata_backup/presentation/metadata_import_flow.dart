import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:hentai_library/core/l10n/app_localizations.dart';
import 'package:hentai_library/core/l10n/app_localizations_x.dart';
import 'package:hentai_library/core/logging/app_log.dart';
import 'package:hentai_library/features/metadata_backup/application/prepare_metadata_import_use_case.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/features/metadata_backup/presentation/providers/metadata_backup_use_case_providers.dart';
import 'package:hentai_library/features/metadata_backup/domain/metadata_backup_file_format.dart';
import 'package:hentai_library/features/metadata_backup/domain/metadata_import_result.dart';
import 'package:hentai_library/features/metadata_backup/presentation/widgets/metadata_import_dialogs.dart';
import 'package:hentai_library/shared/ui/widgets/feedback/app_snackbar.dart';
import 'package:hentai_library/shared/ui/patterns/dialog/lab_dialog_presenter.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

export 'widgets/metadata_import_dialogs.dart';

/// 手动导入 Comic 用户元数据：选文件 → peek → 预演 → 确认 → import → 结果摘要。
Future<void> runMetadataImportFlow(
  BuildContext context, {
  PrepareMetadataImportUseCase? importUseCase,
}) async {
  final AppLocalizations l10n = context.l10n;
  final PrepareMetadataImportUseCase useCase =
      importUseCase ??
      ProviderScope.containerOf(
        context,
        listen: false,
      ).read(prepareMetadataImportUseCaseProvider);

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
    await _showBlockingProgressDialog(
      context,
      title: l10n.settingsMetadataBackupImportPreviewRunningTitle,
      body: l10n.settingsMetadataBackupImportPreviewRunningBody,
    );
    final PreparedMetadataImport prepared = await useCase(rawBytes, path);
    if (context.mounted) {
      Navigator.of(context, rootNavigator: true).pop();
    }

    if (!context.mounted) {
      return;
    }

    final bool? confirmed = await LabDialogPresenter.showBasic<bool>(
      context,
      dialog: MetadataImportConfirmDialog(
        manifest: prepared.manifest,
        preview: prepared.preview,
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

    final MetadataImportResult result = prepared.commit();

    if (context.mounted) {
      Navigator.of(context, rootNavigator: true).pop();
    }

    if (!context.mounted) {
      return;
    }

    await LabDialogPresenter.showBasic<void>(
      context,
      dialog: MetadataImportResultDialog(result: result),
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
}) async {
  // Awaiting dialog dismissal here would prevent the operation that closes it.
  unawaited(
    LabDialogPresenter.showBasic<void>(
      context,
      barrierDismissible: false,
      dialog: PopScope(
        canPop: false,
        child: M3EDialog(
          title: title,
          content: Row(
            children: <Widget>[
              const CircularProgressIndicator(),
              const SizedBox(width: 16),
              Expanded(child: Text(body)),
            ],
          ),
        ),
      ),
    ),
  );
  await Future<void>.delayed(Duration.zero);
}
