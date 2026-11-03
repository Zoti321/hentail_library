import 'dart:typed_data';

import 'package:hentai_library/features/metadata_backup/data/adapters/metadata_backup_frb_adapter.dart';
import 'package:hentai_library/features/metadata_backup/data/adapters/metadata_backup_frb_types.dart';
import 'package:hentai_library/features/metadata_backup/data/mappers/metadata_backup_frb_mapper.dart';
import 'package:hentai_library/features/metadata_backup/domain/metadata_backup_manifest.dart';
import 'package:hentai_library/features/metadata_backup/domain/metadata_backup_repository.dart';
import 'package:hentai_library/features/metadata_backup/domain/metadata_import_preview.dart';
import 'package:hentai_library/features/metadata_backup/domain/metadata_import_result.dart';

class MetadataBackupRepositoryImpl implements MetadataBackupRepository {
  const MetadataBackupRepositoryImpl({MetadataBackupFrbAdapter? adapter})
    : _adapter = adapter ?? const MetadataBackupFrbAdapter();

  final MetadataBackupFrbAdapter _adapter;

  @override
  Uint8List exportComicMetadata({
    String? libraryId,
    required bool includeOrphanFacets,
  }) {
    return _adapter.export(
      options: ExportComicMetadataOptionsDto(
        libraryId: libraryId,
        includeOrphanFacets: includeOrphanFacets,
      ),
    );
  }

  @override
  MetadataBackupManifest peekManifest(Uint8List jsonBytes) {
    return mapMetadataBackupManifestDto(
      _adapter.peek(bytes: jsonBytes),
    );
  }

  @override
  MetadataImportPreview previewImport(Uint8List jsonBytes) {
    return mapMetadataImportPreviewDto(
      _adapter.preview(bytes: jsonBytes),
    );
  }

  @override
  MetadataImportResult importMetadata(Uint8List jsonBytes) {
    return mapMetadataImportResultDto(
      _adapter.import(bytes: jsonBytes),
    );
  }
}
