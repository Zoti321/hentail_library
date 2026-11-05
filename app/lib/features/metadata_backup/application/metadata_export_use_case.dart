import 'dart:io';
import 'dart:typed_data';

import 'package:hentai_library/features/metadata_backup/domain/metadata_export_options.dart';
import 'package:hentai_library/features/metadata_backup/domain/metadata_backup_repository.dart';

/// 手动导出元数据备份：选项 → FRB export → 写入目标路径。
class MetadataExportUseCase {
  const MetadataExportUseCase(this._repository);

  final MetadataBackupRepository _repository;

  Future<String> writeExportToPath({
    required MetadataExportOptions options,
    required String savePath,
  }) async {
    final String extension = options.gzip ? 'hlmeta.json.gz' : 'hlmeta.json';
    final Uint8List raw = _repository.exportComicMetadata(
      libraryId: options.libraryId,
      includeOrphanFacets: options.includeOrphanFacets,
    );
    final List<int> output = options.gzip ? GZipCodec().encode(raw) : raw;
    final String outputPath = ensureMetadataBackupExportExtension(
      savePath,
      extension,
    );
    await File(outputPath).writeAsBytes(output, flush: true);
    return outputPath;
  }
}

String ensureMetadataBackupExportExtension(String savePath, String extension) {
  final String lower = savePath.toLowerCase();
  if (lower.endsWith('.${extension.toLowerCase()}')) {
    return savePath;
  }
  if (lower.endsWith('.json') && extension == 'hlmeta.json') {
    return savePath;
  }
  return '$savePath.$extension';
}
