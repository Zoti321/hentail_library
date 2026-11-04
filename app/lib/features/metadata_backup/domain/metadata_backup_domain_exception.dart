import 'package:hentai_library/shared/domain/exceptions/domain_rule_violation.dart';

final class MetadataBackupDomainException extends DomainRuleViolation {
  const MetadataBackupDomainException._(super.message, {super.code});

  factory MetadataBackupDomainException.missingLibraryIdForScopedExport() {
    return const MetadataBackupDomainException._(
      '按当前库导出时必须指定 libraryId',
      code: 'metadata_backup.missing_library_id',
    );
  }
}
