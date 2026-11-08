import 'package:hentai_library/features/named_metadata/domain/named_facet_form_candidate.dart';

/// Comic metadata form 的 Named facet 候选列表端口。
///
/// 实现见 `data/repositories/named_facet_form_listing.dart`；跨 feature 经
/// `public/named_metadata_form_listing.dart` 的便捷函数或本端口注入。
abstract interface class NamedFacetFormListing {
  /// attachment count DESC、name ASC（core 排序）。
  Future<List<NamedFacetFormCandidate>> listForMetadataForm(
    NamedFacetFormKind facet,
  );
}
