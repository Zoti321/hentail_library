import 'dart:typed_data';

import 'package:hentai_library/features/metadata_backup/domain/metadata_backup_bytes.dart';
import 'package:hentai_library/features/metadata_backup/domain/metadata_backup_manifest.dart';
import 'package:hentai_library/features/metadata_backup/domain/metadata_backup_repository.dart';
import 'package:hentai_library/features/metadata_backup/domain/metadata_import_preview.dart';
import 'package:hentai_library/features/metadata_backup/domain/metadata_import_result.dart';

/// 手动导入元数据备份：解码 → peek → preview → import（无 UI）。
class MetadataImportUseCase {
  const MetadataImportUseCase(this._repository);

  final MetadataBackupRepository _repository;

  Uint8List decodeBackupFileBytes(List<int> rawBytes, String path) {
    return decodeMetadataBackupFileBytes(rawBytes, path);
  }

  MetadataBackupManifest peekManifest(Uint8List jsonBytes) {
    return _repository.peekManifest(jsonBytes);
  }

  MetadataImportPreview previewImport(Uint8List jsonBytes) {
    return _repository.previewImport(jsonBytes);
  }

  MetadataImportResult importMetadata(Uint8List jsonBytes) {
    return _repository.importMetadata(jsonBytes);
  }
}
