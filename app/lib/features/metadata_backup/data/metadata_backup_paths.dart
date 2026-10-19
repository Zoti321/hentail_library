import 'package:hentai_library/features/metadata_backup/domain/metadata_backup_naming.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

const String metadataBackupsDirName = 'metadata_backups';

Future<String> metadataBackupsDirectory() async {
  final directory = await getApplicationSupportDirectory();
  return p.join(directory.path, metadataBackupsDirName);
}

String metadataAutoBackupFileName(DateTime timestamp) {
  final String stamp =
      '${timestamp.year.toString().padLeft(4, '0')}'
      '${timestamp.month.toString().padLeft(2, '0')}'
      '${timestamp.day.toString().padLeft(2, '0')}-'
      '${timestamp.hour.toString().padLeft(2, '0')}'
      '${timestamp.minute.toString().padLeft(2, '0')}'
      '${timestamp.second.toString().padLeft(2, '0')}';
  return '$metadataBackupFilePrefix$stamp$metadataBackupExtension';
}
