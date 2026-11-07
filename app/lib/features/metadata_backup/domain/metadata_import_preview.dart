import 'package:hentai_library/features/metadata_backup/domain/metadata_import_match_tier.dart';

/// Metadata backup import preview（只读预演，GLOSSARY）。
class MetadataImportPreview {
  const MetadataImportPreview({
    required this.wouldApply,
    required this.skippedNotFound,
    required this.skippedAmbiguous,
    required this.wouldUpsertOrphanFacetCount,
    required this.samplesWouldApply,
    required this.samplesNotFound,
    required this.samplesAmbiguous,
  });

  final int wouldApply;
  final int skippedNotFound;
  final int skippedAmbiguous;
  final int wouldUpsertOrphanFacetCount;
  final List<MetadataImportWouldApplySample> samplesWouldApply;
  final List<MetadataImportNotFoundSample> samplesNotFound;
  final List<MetadataImportAmbiguousSample> samplesAmbiguous;
}

class MetadataImportWouldApplySample {
  const MetadataImportWouldApplySample({
    required this.comicId,
    required this.path,
    required this.title,
    required this.matchedComicId,
    this.matchTier,
  });

  final String comicId;
  final String path;
  final String title;
  final String matchedComicId;
  final MetadataImportMatchTier? matchTier;
}

class MetadataImportNotFoundSample {
  const MetadataImportNotFoundSample({
    required this.comicId,
    required this.path,
    required this.title,
  });

  final String comicId;
  final String path;
  final String title;
}

class MetadataImportAmbiguousSample {
  const MetadataImportAmbiguousSample({
    required this.comicId,
    required this.path,
    required this.title,
    required this.candidateComicIds,
  });

  final String comicId;
  final String path;
  final String title;
  final List<String> candidateComicIds;
}
