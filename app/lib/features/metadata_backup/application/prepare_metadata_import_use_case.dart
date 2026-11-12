import 'dart:typed_data';

import 'package:hentai_library/features/metadata_backup/domain/metadata_backup_file_gateway.dart';
import 'package:hentai_library/features/metadata_backup/domain/metadata_backup_manifest.dart';
import 'package:hentai_library/features/metadata_backup/domain/metadata_backup_repository.dart';
import 'package:hentai_library/features/metadata_backup/domain/metadata_import_preview.dart';
import 'package:hentai_library/features/metadata_backup/domain/metadata_import_result.dart';

class PreparedMetadataImport {
  PreparedMetadataImport._(
    this._bytes,
    this.manifest,
    this.preview,
    this._commit,
  );
  final Uint8List _bytes;
  final MetadataBackupManifest manifest;
  final MetadataImportPreview preview;
  final MetadataImportResult Function(Uint8List) _commit;
  MetadataImportResult commit() => _commit(_bytes);
}

/// 解码并预演导入，返回绑定同一份载荷的确认后提交能力。
class PrepareMetadataImportUseCase {
  const PrepareMetadataImportUseCase(this._repository, this._files);
  final MetadataBackupRepository _repository;
  final MetadataBackupFileGateway _files;

  Future<PreparedMetadataImport> call(List<int> rawBytes, String path) async {
    final bytes = await _files.decode(rawBytes, path);
    final manifest = _repository.peekManifest(bytes);
    final preview = _repository.previewImport(bytes);
    return PreparedMetadataImport._(
      bytes,
      manifest,
      preview,
      _repository.importMetadata,
    );
  }
}
