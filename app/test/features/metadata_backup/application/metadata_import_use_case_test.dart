import 'dart:typed_data';

import 'package:hentai_library/features/metadata_backup/application/metadata_import_use_case.dart';
import 'package:hentai_library/features/metadata_backup/domain/metadata_backup_manifest.dart';
import 'package:hentai_library/features/metadata_backup/domain/metadata_backup_repository.dart';
import 'package:hentai_library/features/metadata_backup/domain/metadata_import_preview.dart';
import 'package:hentai_library/features/metadata_backup/domain/metadata_import_result.dart';
import 'package:test/test.dart';

void main() {
  test('previewImport and importMetadata delegate to repository', () {
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
    final MetadataImportUseCase useCase = MetadataImportUseCase(repo);

    expect(useCase.peekManifest(bytes), manifest);
    expect(useCase.previewImport(bytes), preview);
    expect(useCase.importMetadata(bytes), result);
  });
}

class _FakeRepo implements MetadataBackupRepository {
  _FakeRepo({
    required this.manifest,
    required this.preview,
    required this.result,
  });

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
  MetadataImportResult importMetadata(Uint8List jsonBytes) => result;
}
