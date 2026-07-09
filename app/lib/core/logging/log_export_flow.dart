import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:hentai_library/core/logging/app_log.dart';
import 'package:hentai_library/core/logging/app_logging.dart';
import 'package:hentai_library/core/logging/log_export_service.dart';
import 'package:hentai_library/ui/core/widgets/feedback/custom_toast.dart';
import 'package:hentai_library/ui/core/widgets/overlays/dialog/hentai_dialog.dart';
import 'package:intl/intl.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

enum LogRedactionMode { redacted, full }

/// 导出日志完整流程：脱敏选择 → 打包 → 另存为。
Future<void> runLogExportFlow(
  BuildContext context, {
  bool diagnosticVerbose = false,
}) async {
  final LogRedactionMode? mode = await showDialog<LogRedactionMode>(
    context: context,
    builder: (BuildContext context) => const LogExportRedactionDialog(),
  );
  if (mode == null || !context.mounted) {
    return;
  }

  final String defaultName =
      'hentai-library-logs-${DateFormat('yyyyMMdd-HHmmss').format(DateTime.now())}.zip';
  final String? savePath = await FilePicker.platform.saveFile(
    dialogTitle: '保存日志包',
    fileName: defaultName,
    type: FileType.custom,
    allowedExtensions: <String>['zip'],
  );
  if (savePath == null || !context.mounted) {
    return;
  }

  try {
    await appLogFileWriter?.flush();
    final Directory appDir = await getApplicationSupportDirectory();
    final PackageInfo packageInfo = await PackageInfo.fromPlatform();
    final String outputPath = savePath.endsWith('.zip')
        ? savePath
        : '$savePath.zip';

    await const LogExportService().exportToFile(
      outputPath: outputPath,
      logsDirectory: Directory(p.join(appDir.path, 'logs')),
      redact: mode == LogRedactionMode.redacted,
      diagnosticVerbose: diagnosticVerbose,
      packageInfo: packageInfo,
    );

    if (context.mounted) {
      showSuccessToast(context, '日志已导出至 ${p.basename(outputPath)}');
    }
  } catch (e, st) {
    logError(AppLog.core('logging'), '导出日志失败', e, st);
    if (context.mounted) {
      showErrorToast(context, e);
    }
  }
}

class LogExportRedactionDialog extends StatelessWidget {
  const LogExportRedactionDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return HentaiDialog(
      title: '导出日志',
      content: const Text(
        '默认脱敏路径与漫画 ID，适合发给维护者。\n'
        '若排障需要完整路径，请选择「完整日志」并确认隐私风险。',
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          style: TextButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: const Text('取消'),
        ),
        const SizedBox(width: 8),
        OutlinedButton(
          onPressed: () => Navigator.of(context).pop(LogRedactionMode.full),
          style: OutlinedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: const Text('完整日志'),
        ),
        const SizedBox(width: 8),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(LogRedactionMode.redacted),
          style: FilledButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: const Text('脱敏导出'),
        ),
      ],
    );
  }
}
