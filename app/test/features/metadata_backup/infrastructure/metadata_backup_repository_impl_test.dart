import 'dart:typed_data';

import 'package:hentai_library/features/metadata_backup/infrastructure/adapters/metadata_backup_frb_adapter.dart';
import 'package:hentai_library/features/metadata_backup/infrastructure/repositories/metadata_backup_repository_impl.dart';
import 'package:hentai_library/src/rust/api/metadata_backup.dart';
import 'package:test/test.dart';

void main() {
  test('exportComicMetadata 映射 DTO 并委托 FRB 适配器', () {
    String? capturedLibraryId;
    var capturedOrphans = false;

    final MetadataBackupRepositoryImpl repo = MetadataBackupRepositoryImpl(
      adapter: _RecordingAdapter(
        onExport: (ExportComicMetadataOptionsDto options) {
          capturedLibraryId = options.libraryId;
          capturedOrphans = options.includeOrphanFacets;
          return Uint8List.fromList(<int>[7]);
        },
      ),
    );

    final Uint8List bytes = repo.exportComicMetadata(
      libraryId: 'lib-1',
      includeOrphanFacets: true,
    );

    expect(bytes, Uint8List.fromList(<int>[7]));
    expect(capturedLibraryId, 'lib-1');
    expect(capturedOrphans, isTrue);
  });
}

class _RecordingAdapter extends MetadataBackupFrbAdapter {
  _RecordingAdapter({required this.onExport});

  final Uint8List Function(ExportComicMetadataOptionsDto options) onExport;

  @override
  Uint8List export({required ExportComicMetadataOptionsDto options}) =>
      onExport(options);
}
