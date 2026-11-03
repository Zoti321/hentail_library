import 'package:hentai_library/features/named_metadata/data/adapters/named_facet_form_frb_adapter.dart';
import 'package:hentai_library/features/named_metadata/domain/named_facet_form_candidate.dart';
import 'package:hentai_library/src/rust/api/named_facet/types.dart'
    as rust_types;

/// Loads Comic metadata form candidates (attachment count DESC, name ASC).
Future<List<NamedFacetFormCandidate>> listNamedFacetForMetadataForm(
  NamedFacetFormKind facet, {
  NamedFacetFormFrbAdapter? adapter,
}) async {
  final NamedFacetFormFrbAdapter resolved =
      adapter ?? const NamedFacetFormFrbAdapter();
  final List<rust_types.NamedFacetFormEntryFrbDto> rows = await resolved.listForForm(
    facet,
  );
  return rows
      .map(
        (rust_types.NamedFacetFormEntryFrbDto e) => namedFacetFormCandidate(
          name: e.name,
          attachmentCount: e.attachmentCount.toInt(),
        ),
      )
      .toList(growable: false);
}
