import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

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
      return fileName.startsWith('app_log_') ||
          fileName.startsWith('rust_log_');
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
    final String? home = homeDirectory ?? _defaultHomeDirectory();

    final List<({String name, Uint8List bytes})> entries =
        <({String name, Uint8List bytes})>[];
    for (final File file in logFiles) {
      entries.add((
        name: p.basename(file.path),
        bytes: await file.readAsBytes(),
      ));
    }

    final Map<String, Object?> manifest = buildDiagnosticsManifest(
      packageInfo: packageInfo,
      diagnosticVerbose: diagnosticVerbose,
    );

    final List<int> zipBytes = await Isolate.run(
      () => buildLogExportZipBytes(
        entries: entries,
        redact: redact,
        homeDirectory: home,
        manifest: manifest,
      ),
    );

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

/// CPU-bound zip assembly (optional redact + ZipEncoder). Safe for [Isolate.run].
List<int> buildLogExportZipBytes({
  required List<({String name, Uint8List bytes})> entries,
  required bool redact,
  required String? homeDirectory,
  required Map<String, Object?> manifest,
}) {
  final Archive archive = Archive();

  for (final ({String name, Uint8List bytes}) entry in entries) {
    List<int> bytes = entry.bytes;
    if (redact) {
      final String text = utf8.decode(bytes, allowMalformed: true);
      bytes = utf8.encode(redactLogText(text, homeDirectory: homeDirectory));
    }
    archive.addFile(ArchiveFile(entry.name, bytes.length, bytes));
  }

  final List<int> manifestBytes = utf8.encode(
    const JsonEncoder.withIndent('  ').convert(manifest),
  );
  archive.addFile(
    ArchiveFile('diagnostics.json', manifestBytes.length, manifestBytes),
  );

  return ZipEncoder().encode(archive);
}
