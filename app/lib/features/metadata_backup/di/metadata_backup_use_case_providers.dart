import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/features/metadata_backup/application/metadata_export_use_case.dart';
import 'package:hentai_library/features/metadata_backup/application/metadata_import_use_case.dart';
import 'package:hentai_library/features/metadata_backup/di/metadata_backup_repository_provider.dart';

final Provider<MetadataExportUseCase> metadataExportUseCaseProvider =
    Provider<MetadataExportUseCase>(
      (Ref ref) =>
          MetadataExportUseCase(ref.read(metadataBackupRepositoryProvider)),
    );

final Provider<MetadataImportUseCase> metadataImportUseCaseProvider =
    Provider<MetadataImportUseCase>(
      (Ref ref) =>
          MetadataImportUseCase(ref.read(metadataBackupRepositoryProvider)),
    );
