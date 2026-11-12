/// 跨 feature Comic metadata form 候选加载（ADR-0034）。
///
/// 导出 domain 端口 / 候选类型；便捷函数委托 data 实现，不 export data 路径。
library;

import 'package:hentai_library/features/comic_metadata/data/repositories/named_facet_form_listing.dart';
import 'package:hentai_library/features/comic_metadata/domain/named_facet_form_candidate.dart';
import 'package:hentai_library/features/comic_metadata/domain/named_facet_form_listing.dart';

export 'package:hentai_library/features/comic_metadata/domain/named_facet_form_candidate.dart';
export 'package:hentai_library/features/comic_metadata/domain/named_facet_form_listing.dart';

/// Loads Comic metadata form candidates (attachment count DESC, name ASC).
Future<List<NamedFacetFormCandidate>> listNamedFacetForMetadataForm(
  NamedFacetFormKind facet, {
  NamedFacetFormListing? listing,
}) {
  return (listing ?? const NamedFacetFormListingImpl()).listForMetadataForm(
    facet,
  );
}
