import 'package:hentai_library/features/metadata_backup/data/metadata_backup_file_gateway.dart';

import 'dart:typed_data';

import 'package:hentai_library/features/metadata_backup/application/prepare_metadata_import_use_case.dart';
import 'package:hentai_library/features/metadata_backup/domain/metadata_backup_manifest.dart';
import 'package:hentai_library/features/metadata_backup/domain/metadata_backup_repository.dart';
import 'package:hentai_library/features/metadata_backup/domain/metadata_import_preview.dart';
import 'package:hentai_library/features/metadata_backup/domain/metadata_import_result.dart';
import 'package:test/test.dart';

void main() {
  test(
    'prepare does not commit and commit uses the prepared payload',
    () async {
      const MetadataBackupManifest manifest = MetadataBackupManifest(
        schemaVersion: 1,
        exportedAt: 't',
        appVersion: '0',
        comicCount: 0,
        includeOrphanFacets: false,
      );
      const MetadataImportPreview preview = MetadataImportPreview(
        wouldApply: 1,
        skippedNotFound: 0,
        skippedAmbiguous: 0,
        wouldUpsertOrphanFacetCount: 0,
        samplesWouldApply: <MetadataImportWouldApplySample>[],
        samplesNotFound: <MetadataImportNotFoundSample>[],
        samplesAmbiguous: <MetadataImportAmbiguousSample>[],
      );
      const MetadataImportResult result = MetadataImportResult(
        applied: 1,
        skippedNotFound: 0,
        skippedAmbiguous: 0,
        errors: <String>[],
      );

      final Uint8List bytes = Uint8List.fromList(<int>[9]);
      final _FakeRepo repo = _FakeRepo(
        manifest: manifest,
        preview: preview,
        result: result,
      );
      final useCase = PrepareMetadataImportUseCase(
        repo,
        const LocalMetadataBackupFileGateway(),
      );

      final prepared = await useCase(bytes, 'backup.hlmeta.json');
      expect(prepared.manifest, manifest);
      expect(prepared.preview, preview);
      expect(repo.imported, isNull);
      bytes[0] = 42;
      expect(prepared.commit(), result);
      expect(repo.imported, [9]);
    },
  );
}

class _FakeRepo implements MetadataBackupRepository {
  _FakeRepo({
    required this.manifest,
    required this.preview,
    required this.result,
  });

  Uint8List? imported;
  final MetadataBackupManifest manifest;
  final MetadataImportPreview preview;
  final MetadataImportResult result;

  @override
  Uint8List exportComicMetadata({
    String? libraryId,
    required bool includeOrphanFacets,
  }) => throw UnimplementedError();

  @override
  MetadataBackupManifest peekManifest(Uint8List jsonBytes) => manifest;

  @override
  MetadataImportPreview previewImport(Uint8List jsonBytes) => preview;

  @override
  MetadataImportResult importMetadata(Uint8List jsonBytes) {
    imported = jsonBytes;
    return result;
  }
}
