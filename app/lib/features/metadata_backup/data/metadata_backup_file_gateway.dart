import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;
import 'package:hentai_library/features/metadata_backup/domain/metadata_backup_file_gateway.dart';
import 'package:hentai_library/features/metadata_backup/domain/metadata_backup_naming.dart';
import 'package:hentai_library/features/metadata_backup/domain/metadata_backup_bytes.dart';
import 'package:hentai_library/features/metadata_backup/data/metadata_backup_paths.dart';

class LocalMetadataBackupFileGateway implements MetadataBackupFileGateway {
  const LocalMetadataBackupFileGateway();
  @override
  Future<Uint8List> decode(List<int> bytes, String path) =>
      decodeMetadataBackupFileBytes(bytes, path);
  @override
  Future<List<int>> compress(Uint8List bytes) =>
      encodeMetadataBackupGzip(bytes);
  @override
  Future<void> write(String path, List<int> bytes) async {
    await File(path).writeAsBytes(bytes, flush: true);
  }

  @override
  Future<String> prepareBackupDirectory() async {
    final path = await metadataBackupsDirectory();
    await Directory(path).create(recursive: true);
    return path;
  }

  @override
  String backupPath(String directory, String fileName) =>
      p.join(directory, fileName);
  @override
  void prune(String directory, {required int maxFiles}) =>
      pruneMetadataBackupFiles(directory, maxFiles: maxFiles);
}

List<File> listMetadataBackupFiles(String directoryPath) {
  final Directory directory = Directory(directoryPath);
  if (!directory.existsSync()) {
    return <File>[];
  }
  final List<File> files = directory
      .listSync()
      .whereType<File>()
      .where(
        (File file) =>
            p.basename(file.path).startsWith(metadataBackupFilePrefix),
      )
      .toList();
  files.sort((File a, File b) {
    final int modified = b.lastModifiedSync().compareTo(a.lastModifiedSync());
    if (modified != 0) {
      return modified;
    }
    return b.path.compareTo(a.path);
  });
  return files;
}

void pruneMetadataBackupFiles(String directoryPath, {int maxFiles = 3}) {
  final List<File> files = listMetadataBackupFiles(directoryPath);
  if (files.length <= maxFiles) {
    return;
  }
  for (final File file in files.skip(maxFiles)) {
    try {
      file.deleteSync();
    } on FileSystemException {
      // Best-effort rotation.
    }
  }
}
