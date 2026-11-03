import 'dart:typed_data';

import 'package:hentai_library/features/metadata_backup/domain/metadata_backup_manifest.dart';
import 'package:hentai_library/features/metadata_backup/domain/metadata_import_preview.dart';
import 'package:hentai_library/features/metadata_backup/domain/metadata_import_result.dart';

/// Comic 用户元数据备份仓储（Rust 真值经 FRB，由 data 层实现）。
abstract interface class MetadataBackupRepository {
  Uint8List exportComicMetadata({
    String? libraryId,
    required bool includeOrphanFacets,
  });

  MetadataBackupManifest peekManifest(Uint8List jsonBytes);

  MetadataImportPreview previewImport(Uint8List jsonBytes);

  MetadataImportResult importMetadata(Uint8List jsonBytes);
}
