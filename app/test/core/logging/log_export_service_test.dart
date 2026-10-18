import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:hentai_library/core/logging/log_export_service.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  group('LogExportService', () {
    test('exportToFile bundles logs and diagnostics.json', () async {
      final Directory temp = await Directory.systemTemp.createTemp(
        'log_export_',
      );
      addTearDown(() => temp.delete(recursive: true));

      final Directory logsDir = Directory(p.join(temp.path, 'logs'));
      await logsDir.create(recursive: true);
      await File(
        p.join(logsDir.path, 'app_log.txt'),
      ).writeAsString('dart line');
      await File(
        p.join(logsDir.path, 'rust_log.txt'),
      ).writeAsString('rust line comic_id=secret');

      final String zipPath = p.join(temp.path, 'export.zip');
      const LogExportService service = LogExportService();
      await service.exportToFile(
        outputPath: zipPath,
        logsDirectory: logsDir,
        redact: true,
        diagnosticVerbose: false,
        packageInfo: PackageInfo(
          appName: 'hentai_library',
          packageName: 'hentai_library',
          version: '0.0.1',
          buildNumber: '1',
        ),
        homeDirectory: null,
      );

      final List<int> zipBytes = await File(zipPath).readAsBytes();
      final Archive archive = ZipDecoder().decodeBytes(zipBytes);
      final Map<String, ArchiveFile> files = <String, ArchiveFile>{
        for (final ArchiveFile file in archive.files) file.name: file,
      };

      expect(files.containsKey('app_log.txt'), isTrue);
      expect(files.containsKey('rust_log.txt'), isTrue);
      expect(files.containsKey('diagnostics.json'), isTrue);

      final String rustText = utf8.decode(files['rust_log.txt']!.content);
      expect(rustText, isNot(contains('secret')));
      expect(rustText, contains('comic_id='));

      final Map<String, dynamic> manifest =
          jsonDecode(utf8.decode(files['diagnostics.json']!.content))
              as Map<String, dynamic>;
      expect(manifest['app_version'], '0.0.1');
      expect(manifest['diagnostic_verbose'], isFalse);
    });

    test('isBundledLogFileName matches rotation backups', () {
      expect(LogExportService.isBundledLogFileName('app_log.txt'), isTrue);
      expect(LogExportService.isBundledLogFileName('rust_log_123.bak'), isTrue);
      expect(LogExportService.isBundledLogFileName('other.txt'), isFalse);
    });
  });
}
