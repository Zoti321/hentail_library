import 'dart:io';

import 'package:hentai_library/features/app_settings/infrastructure/diagnostics/log_export_service.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

Future<void> exportLogs({
  required String outputPath,
  required bool redact,
  required bool diagnosticVerbose,
  required Future<void> Function() flush,
}) async {
  await flush();
  final Directory appDir = await getApplicationSupportDirectory();
  final PackageInfo packageInfo = await PackageInfo.fromPlatform();
  await const LogExportService().exportToFile(
    outputPath: outputPath,
    logsDirectory: Directory(p.join(appDir.path, 'logs')),
    redact: redact,
    diagnosticVerbose: diagnosticVerbose,
    packageInfo: packageInfo,
  );
}
