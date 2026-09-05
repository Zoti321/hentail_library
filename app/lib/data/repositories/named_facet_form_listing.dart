import 'package:hentai_library/data/adapters/frb_call_guard.dart';
import 'package:hentai_library/domain/models/named_facet_form_candidate.dart';
import 'package:hentai_library/src/rust/api/named_facet.dart' as rust;

/// Loads Comic metadata form candidates (attachment count DESC, name ASC).
Future<List<NamedFacetFormCandidate>> listNamedFacetForMetadataForm(
  NamedFacetFormKind facet,
) async {
  return guardFrbSync(
    () => rust
        .listNamedFacetForFormFrb(facet: _toFrb(facet))
        .map(
          (rust.NamedFacetFormEntryFrbDto e) => namedFacetFormCandidate(
            name: e.name,
            attachmentCount: e.attachmentCount.toInt(),
          ),
        )
        .toList(growable: false),
    fallbackMessage: switch (facet) {
      NamedFacetFormKind.tag => '读取标签列表失败',
      NamedFacetFormKind.author => '读取作者列表失败',
      NamedFacetFormKind.parody => '读取原作列表失败',
      NamedFacetFormKind.character => '读取角色列表失败',
    },
  );
}

rust.JunctionNamedFacetFrb _toFrb(NamedFacetFormKind facet) => switch (facet) {
  NamedFacetFormKind.tag => rust.JunctionNamedFacetFrb.tag,
  NamedFacetFormKind.author => rust.JunctionNamedFacetFrb.author,
  NamedFacetFormKind.parody => rust.JunctionNamedFacetFrb.parody,
  NamedFacetFormKind.character => rust.JunctionNamedFacetFrb.character,
};
