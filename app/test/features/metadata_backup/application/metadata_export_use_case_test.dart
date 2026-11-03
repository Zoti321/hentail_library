import 'dart:io';
import 'dart:typed_data';

import 'package:hentai_library/features/metadata_backup/application/metadata_export_use_case.dart';
import 'package:hentai_library/features/metadata_backup/domain/metadata_export_options.dart';
import 'package:hentai_library/features/metadata_backup/domain/metadata_backup_manifest.dart';
import 'package:hentai_library/features/metadata_backup/domain/metadata_backup_repository.dart';
import 'package:hentai_library/features/metadata_backup/domain/metadata_import_preview.dart';
import 'package:hentai_library/features/metadata_backup/domain/metadata_import_result.dart';
import 'package:test/test.dart';

void main() {
  test('writeExportToPath writes gzip when enabled', () async {
    final Directory dir = await Directory.systemTemp.createTemp(
      'metadata_export_use_case_',
    );
    addTearDown(() => dir.deleteSync(recursive: true));

    final _FakeRepo repo = _FakeRepo(
      onExport: () => Uint8List.fromList(<int>[1, 2]),
    );
    final MetadataExportUseCase useCase = MetadataExportUseCase(repo);

    final String path = await useCase.writeExportToPath(
      options: const MetadataExportOptions(gzip: true),
      savePath: '${dir.path}/out',
    );

    expect(path.endsWith('.hlmeta.json.gz'), isTrue);
    final List<int> written = await File(path).readAsBytes();
    expect(GZipCodec().decode(written), <int>[1, 2]);
  });
}

class _FakeRepo implements MetadataBackupRepository {
  _FakeRepo({required this.onExport});

  final Uint8List Function() onExport;

  @override
  Uint8List exportComicMetadata({
    String? libraryId,
    required bool includeOrphanFacets,
  }) => onExport();

  @override
  MetadataBackupManifest peekManifest(Uint8List jsonBytes) =>
      throw UnimplementedError();

  @override
  MetadataImportPreview previewImport(Uint8List jsonBytes) =>
      throw UnimplementedError();

  @override
  MetadataImportResult importMetadata(Uint8List jsonBytes) =>
      throw UnimplementedError();
}
