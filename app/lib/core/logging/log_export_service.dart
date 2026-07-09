import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:hentai_library/core/logging/log_export_manifest.dart';
import 'package:hentai_library/core/logging/log_redactor.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path/path.dart' as p;

class LogExportService {
  const LogExportService();

  static bool isBundledLogFileName(String fileName) {
    if (fileName == 'app_log.txt' || fileName == 'rust_log.txt') {
      return true;
    }
    if (fileName.endsWith('.bak')) {
      return fileName.startsWith('app_log_') || fileName.startsWith('rust_log_');
    }
    return false;
  }

  Future<List<File>> listLogFiles(Directory logsDirectory) async {
    if (!await logsDirectory.exists()) {
      return <File>[];
    }
    final List<File> files = <File>[];
    await for (final FileSystemEntity entity in logsDirectory.list()) {
      if (entity is! File) {
        continue;
      }
      final String name = p.basename(entity.path);
      if (isBundledLogFileName(name)) {
        files.add(entity);
      }
    }
    files.sort(
      (File a, File b) => p.basename(a.path).compareTo(p.basename(b.path)),
    );
    return files;
  }

  Future<void> exportToFile({
    required String outputPath,
    required Directory logsDirectory,
    required bool redact,
    required bool diagnosticVerbose,
    required PackageInfo packageInfo,
    String? homeDirectory,
  }) async {
    final List<File> logFiles = await listLogFiles(logsDirectory);
    final Archive archive = Archive();
    final String? home = homeDirectory ?? _defaultHomeDirectory();

    for (final File file in logFiles) {
      final String archiveName = p.basename(file.path);
      var bytes = await file.readAsBytes();
      if (redact) {
        final String text = utf8.decode(bytes, allowMalformed: true);
        bytes = utf8.encode(redactLogText(text, homeDirectory: home));
      }
      archive.addFile(ArchiveFile(archiveName, bytes.length, bytes));
    }

    final Map<String, Object?> manifest = buildDiagnosticsManifest(
      packageInfo: packageInfo,
      diagnosticVerbose: diagnosticVerbose,
    );
    final List<int> manifestBytes = utf8.encode(
      const JsonEncoder.withIndent('  ').convert(manifest),
    );
    archive.addFile(
      ArchiveFile('diagnostics.json', manifestBytes.length, manifestBytes),
    );

    final List<int> zipBytes = ZipEncoder().encode(archive);

    final File outputFile = File(outputPath);
    await outputFile.parent.create(recursive: true);
    await outputFile.writeAsBytes(zipBytes, flush: true);
  }

  String? _defaultHomeDirectory() {
    if (Platform.isWindows) {
      return Platform.environment['USERPROFILE'];
    }
    return Platform.environment['HOME'];
  }
}
