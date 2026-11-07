import 'package:hentai_library/shared/domain/exceptions/domain_exception.dart';

final class MetadataBackupException extends DomainException {
  const MetadataBackupException._(super.message, {super.code});

  factory MetadataBackupException.missingLibraryIdForScopedExport() {
    return const MetadataBackupException._(
      '按当前库导出时必须指定 libraryId',
      code: 'metadata_backup.missing_library_id',
    );
  }
}
