import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/features/metadata_backup/data/repositories/metadata_backup_repository_impl.dart';
import 'package:hentai_library/features/metadata_backup/domain/metadata_backup_repository.dart';

/// Feature 内导出仓储；跨 feature 仍经 `shared/di` 槽位，不暴露本 Provider。
final Provider<MetadataBackupRepository> metadataBackupRepositoryProvider =
    Provider<MetadataBackupRepository>(
      (Ref ref) => const MetadataBackupRepositoryImpl(),
    );
