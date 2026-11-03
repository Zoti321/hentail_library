import 'dart:io';

import 'package:hentai_library/features/metadata_backup/data/metadata_backup_paths.dart';
import 'package:hentai_library/features/metadata_backup/domain/metadata_auto_backup_logic.dart';

/// 最近一次元数据备份的时间；无备份或读取失败时为 null。
///
/// 由 bootstrap 通过 `shared/di` 的 slot 注入 app_settings（#264）。
Future<DateTime?> readRecentMetadataBackupAt() async {
  try {
    final String backupsDir = await metadataBackupsDirectory();
    final List<File> files = listMetadataBackupFiles(backupsDir);
    if (files.isEmpty) {
      return null;
    }
    return files.first.lastModifiedSync();
  } on Object {
    return null;
  }
}
