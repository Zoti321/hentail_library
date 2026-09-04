import 'package:hentai_library/data/adapters/frb_call_guard.dart';
import 'package:hentai_library/domain/models/named_facet_form_candidate.dart';
import 'package:hentai_library/src/rust/api/named_facet.dart' as rust;

/// Loads Comic metadata form candidates (attachment count DESC, name ASC).
Future<List<NamedFacetFormCandidate>> listNamedFacetForMetadataForm(
  rust.JunctionNamedFacetFrb facet,
) async {
  return guardFrbSync(
    () => rust
        .listNamedFacetForFormFrb(facet: facet)
        .map(
          (rust.NamedFacetFormEntryFrbDto e) => namedFacetFormCandidate(
            name: e.name,
            attachmentCount: e.attachmentCount.toInt(),
          ),
        )
        .toList(growable: false),
    fallbackMessage: switch (facet) {
      rust.JunctionNamedFacetFrb.tag => '读取标签列表失败',
      rust.JunctionNamedFacetFrb.author => '读取作者列表失败',
      rust.JunctionNamedFacetFrb.parody => '读取原作列表失败',
      rust.JunctionNamedFacetFrb.character => '读取角色列表失败',
    },
  );
}
