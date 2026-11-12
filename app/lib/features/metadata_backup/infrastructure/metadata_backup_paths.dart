export 'package:hentai_library/features/metadata_backup/domain/metadata_backup_naming.dart'
    show metadataAutoBackupFileName;

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

const String metadataBackupsDirName = 'metadata_backups';

Future<String> metadataBackupsDirectory() async {
  final directory = await getApplicationSupportDirectory();
  return p.join(directory.path, metadataBackupsDirName);
}
