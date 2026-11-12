import 'package:hentai_library/features/metadata_backup/domain/metadata_backup_file_gateway.dart';
import 'package:hentai_library/features/metadata_backup/data/metadata_backup_file_gateway.dart';
import 'package:hentai_library/features/metadata_backup/application/run_metadata_auto_backup_use_case.dart';
import 'package:hentai_library/features/metadata_backup/presentation/view_models/metadata_last_auto_backup_notifier.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/features/metadata_backup/application/metadata_export_use_case.dart';
import 'package:hentai_library/features/metadata_backup/application/prepare_metadata_import_use_case.dart';
import 'package:hentai_library/features/metadata_backup/di/metadata_backup_repository_provider.dart';

final Provider<MetadataExportUseCase> metadataExportUseCaseProvider =
    Provider<MetadataExportUseCase>(
      (Ref ref) => MetadataExportUseCase(
        ref.read(metadataBackupRepositoryProvider),
        ref.read(metadataBackupFileGatewayProvider),
      ),
    );

final Provider<PrepareMetadataImportUseCase>
prepareMetadataImportUseCaseProvider = Provider<PrepareMetadataImportUseCase>(
  (Ref ref) => PrepareMetadataImportUseCase(
    ref.read(metadataBackupRepositoryProvider),
    ref.read(metadataBackupFileGatewayProvider),
  ),
);

final metadataBackupFileGatewayProvider = Provider<MetadataBackupFileGateway>(
  (ref) => const LocalMetadataBackupFileGateway(),
);
final runMetadataAutoBackupUseCaseProvider =
    Provider<RunMetadataAutoBackupUseCase>(
      (ref) => RunMetadataAutoBackupUseCase(
        repository: ref.read(metadataBackupRepositoryProvider),
        files: ref.read(metadataBackupFileGatewayProvider),
        recordCompletion: (at) =>
            ref.read(metadataLastAutoBackupProvider.notifier).recordBackup(at),
      ),
    );
