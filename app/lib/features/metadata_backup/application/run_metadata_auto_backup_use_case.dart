import 'package:hentai_library/features/metadata_backup/domain/metadata_backup_repository.dart';
import 'package:hentai_library/features/metadata_backup/domain/metadata_backup_file_gateway.dart';
import 'package:hentai_library/features/metadata_backup/domain/metadata_auto_backup_logic.dart';
import 'package:hentai_library/features/metadata_backup/domain/metadata_backup_naming.dart';

/// 串行执行自动备份，并仅在写入与轮替完成后记录成功时间。
class RunMetadataAutoBackupUseCase {
  RunMetadataAutoBackupUseCase({
    required this.repository,
    required this.files,
    required this.recordCompletion,
  });
  final MetadataBackupRepository repository;
  final MetadataBackupFileGateway files;
  final Future<void> Function(DateTime) recordCompletion;
  bool _inFlight = false;

  Future<void> call({
    required bool enabled,
    required bool fromStartup,
    bool force = false,
    DateTime? lastBackupAt,
    DateTime Function()? now,
  }) async {
    if (_inFlight || (!enabled && !force)) {
      return;
    }
    final clock = now ?? DateTime.now;
    if (!force &&
        fromStartup &&
        !shouldRunStartupMetadataAutoBackup(
          now: clock(),
          lastBackupAt: lastBackupAt,
        )) {
      return;
    }
    _inFlight = true;
    try {
      final timestamp = clock();
      final directory = await files.prepareBackupDirectory();
      final raw = repository.exportComicMetadata(includeOrphanFacets: false);
      final compressed = await files.compress(raw);
      await files.write(
        files.backupPath(directory, metadataAutoBackupFileName(timestamp)),
        compressed,
      );
      files.prune(directory, maxFiles: metadataAutoBackupMaxFiles);
      await recordCompletion(timestamp);
    } finally {
      _inFlight = false;
    }
  }
}
