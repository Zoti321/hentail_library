import 'package:hentai_library/features/metadata_backup/domain/metadata_import_match_tier.dart';
import 'package:hentai_library/features/metadata_backup/domain/metadata_import_preview.dart';
import 'package:hentai_library/src/rust/api/metadata_backup.dart' as rust;
import 'package:hentai_library/features/metadata_backup/data/mappers/metadata_backup_frb_mapper.dart';
import 'package:test/test.dart';

void main() {
  test('mapMetadataImportPreviewDto maps match tier and samples', () {
    const rust.PreviewImportComicMetadataResultDto dto =
        rust.PreviewImportComicMetadataResultDto(
          wouldApply: 1,
          skippedNotFound: 0,
          skippedAmbiguous: 0,
          wouldUpsertOrphanFacetCount: 0,
          samplesWouldApply: <rust.WouldApplySampleDto>[
            rust.WouldApplySampleDto(
              comicId: 'b1',
              path: '/p',
              title: 'T',
              matchedComicId: 'c1',
              matchTier: rust.MatchTierDto.libraryRelative,
            ),
          ],
          samplesNotFound: <rust.NotFoundSampleDto>[],
          samplesAmbiguous: <rust.AmbiguousSampleDto>[],
        );

    final MetadataImportPreview preview = mapMetadataImportPreviewDto(dto);

    expect(preview.wouldApply, 1);
    expect(preview.samplesWouldApply.single.matchTier,
        MetadataImportMatchTier.libraryRelative);
  });
}
