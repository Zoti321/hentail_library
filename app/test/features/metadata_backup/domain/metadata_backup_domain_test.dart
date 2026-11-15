import 'package:hentai_library/features/metadata_backup/domain/metadata_export_options.dart';
import 'package:test/test.dart';

void main() {
  test('MetadataExportOptions accepts all-library export', () {
    expect(const MetadataExportOptions().isValid, isTrue);
  });

  test('MetadataExportOptions normalizes library id', () {
    expect(
      const MetadataExportOptions(libraryId: '  lib-a  ')
          .normalized()
          .libraryId,
      'lib-a',
    );
  });
}
