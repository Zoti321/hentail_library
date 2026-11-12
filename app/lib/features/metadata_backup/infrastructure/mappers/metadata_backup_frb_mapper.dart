import 'package:hentai_library/features/metadata_backup/domain/metadata_backup_manifest.dart';
import 'package:hentai_library/features/metadata_backup/domain/metadata_import_match_tier.dart';
import 'package:hentai_library/features/metadata_backup/domain/metadata_import_preview.dart';
import 'package:hentai_library/features/metadata_backup/domain/metadata_import_result.dart';
import 'package:hentai_library/src/rust/api/metadata_backup.dart' as rust;

MetadataBackupManifest mapMetadataBackupManifestDto(
  rust.MetadataBackupManifestDto dto,
) {
  return MetadataBackupManifest(
    schemaVersion: dto.schemaVersion,
    exportedAt: dto.exportedAt,
    appVersion: dto.appVersion,
    comicCount: dto.comicCount,
    includeOrphanFacets: dto.includeOrphanFacets,
    libraryId: dto.libraryId,
  );
}

MetadataImportPreview mapMetadataImportPreviewDto(
  rust.PreviewImportComicMetadataResultDto dto,
) {
  return MetadataImportPreview(
    wouldApply: dto.wouldApply,
    skippedNotFound: dto.skippedNotFound,
    skippedAmbiguous: dto.skippedAmbiguous,
    wouldUpsertOrphanFacetCount: dto.wouldUpsertOrphanFacetCount,
    samplesWouldApply: dto.samplesWouldApply
        .map(mapMetadataImportWouldApplySampleDto)
        .toList(growable: false),
    samplesNotFound: dto.samplesNotFound
        .map(mapMetadataImportNotFoundSampleDto)
        .toList(growable: false),
    samplesAmbiguous: dto.samplesAmbiguous
        .map(mapMetadataImportAmbiguousSampleDto)
        .toList(growable: false),
  );
}

MetadataImportWouldApplySample mapMetadataImportWouldApplySampleDto(
  rust.WouldApplySampleDto dto,
) {
  return MetadataImportWouldApplySample(
    comicId: dto.comicId,
    path: dto.path,
    title: dto.title,
    matchedComicId: dto.matchedComicId,
    matchTier: mapMetadataImportMatchTierDto(dto.matchTier),
  );
}

MetadataImportNotFoundSample mapMetadataImportNotFoundSampleDto(
  rust.NotFoundSampleDto dto,
) {
  return MetadataImportNotFoundSample(
    comicId: dto.comicId,
    path: dto.path,
    title: dto.title,
  );
}

MetadataImportAmbiguousSample mapMetadataImportAmbiguousSampleDto(
  rust.AmbiguousSampleDto dto,
) {
  return MetadataImportAmbiguousSample(
    comicId: dto.comicId,
    path: dto.path,
    title: dto.title,
    candidateComicIds: List<String>.of(dto.candidateComicIds),
  );
}

MetadataImportMatchTier? mapMetadataImportMatchTierDto(rust.MatchTierDto? dto) {
  if (dto == null) {
    return null;
  }
  return switch (dto) {
    rust.MatchTierDto.path => MetadataImportMatchTier.path,
    rust.MatchTierDto.libraryRelative =>
      MetadataImportMatchTier.libraryRelative,
  };
}

MetadataImportResult mapMetadataImportResultDto(
  rust.ImportComicMetadataResultDto dto,
) {
  return MetadataImportResult(
    applied: dto.applied,
    skippedNotFound: dto.skippedNotFound,
    skippedAmbiguous: dto.skippedAmbiguous,
    errors: List<String>.of(dto.errors),
  );
}
