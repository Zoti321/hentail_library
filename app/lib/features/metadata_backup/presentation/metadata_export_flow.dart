import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:hentai_library/core/l10n/app_localizations.dart';
import 'package:hentai_library/core/l10n/app_localizations_x.dart';
import 'package:hentai_library/core/logging/app_log.dart';
import 'package:hentai_library/features/metadata_backup/application/metadata_export_use_case.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/features/metadata_backup/presentation/providers/metadata_backup_use_case_providers.dart';
import 'package:hentai_library/features/metadata_backup/domain/metadata_export_options.dart';
import 'package:hentai_library/features/metadata_backup/presentation/widgets/metadata_export_options_dialog.dart';
import 'package:hentai_library/shared/ui/widgets/feedback/app_snackbar.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;

export 'widgets/metadata_export_options_dialog.dart';

/// 手动导出 Comic 用户元数据：选项 dialog → 另存为 → 用例写入 → Toast。
Future<void> runMetadataExportFlow(
  BuildContext context, {
  required MetadataExportOptions initialOptions,
  MetadataExportUseCase? exportUseCase,
}) async {
  final MetadataExportOptions? options = await showMetadataExportOptionsDialog(
    context: context,
    initialOptions: initialOptions,
  );
  if (options == null || !context.mounted) {
    return;
  }

  final AppLocalizations l10n = context.l10n;
  final String extension = options.gzip ? 'hlmeta.json.gz' : 'hlmeta.json';
  final String defaultName =
      'metadata-${DateFormat('yyyyMMdd-HHmmss').format(DateTime.now())}.$extension';
  final String? savePath = await FilePicker.saveFile(
    dialogTitle: l10n.settingsMetadataBackupExportSaveDialogTitle,
    fileName: defaultName,
    type: FileType.custom,
    allowedExtensions: <String>[extension],
  );
  if (savePath == null || !context.mounted) {
    return;
  }

  final MetadataExportUseCase useCase =
      exportUseCase ??
      ProviderScope.containerOf(
        context,
        listen: false,
      ).read(metadataExportUseCaseProvider);

  try {
    final String outputPath = await useCase.writeExportToPath(
      options: options,
      savePath: savePath,
    );

    if (context.mounted) {
      showSuccessSnackbar(
        context,
        l10n.settingsMetadataBackupExportSuccess(p.basename(outputPath)),
      );
    }
  } catch (e, st) {
    logError(AppLog.core('metadata_backup'), '导出元数据失败', e, st);
    if (context.mounted) {
      showErrorSnackbar(context, e);
    }
  }
}
