import 'package:hentai_library/features/comic_metadata/infrastructure/adapters/named_facet_form_frb_adapter.dart';
import 'package:hentai_library/features/comic_metadata/domain/named_facet_form_candidate.dart';
import 'package:hentai_library/features/comic_metadata/domain/named_facet_form_listing.dart';
import 'package:hentai_library/src/rust/api/named_facet/types.dart'
    as rust_types;

/// [NamedFacetFormListing] 的 FRB 实现。
class NamedFacetFormListingImpl implements NamedFacetFormListing {
  const NamedFacetFormListingImpl({
    this.adapter = const NamedFacetFormFrbAdapter(),
  });

  final NamedFacetFormFrbAdapter adapter;

  @override
  Future<List<NamedFacetFormCandidate>> listForMetadataForm(
    NamedFacetFormKind facet,
  ) async {
    final List<rust_types.NamedFacetFormEntryFrbDto> rows = await adapter
        .listForForm(facet);
    return rows
        .map(
          (rust_types.NamedFacetFormEntryFrbDto e) => namedFacetFormCandidate(
            name: e.name,
            attachmentCount: e.attachmentCount.toInt(),
          ),
        )
        .toList(growable: false);
  }
}
